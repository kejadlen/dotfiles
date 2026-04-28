# Rust backend services

Project-type-specific guidance for long-running HTTP services. Read
`scaffolding.md` first for shared project shape, then return here for
server-specific additions and the deploy workflow.

## Cargo.toml additions

On top of the baseline in `scaffolding.md`:

```toml
[dependencies]
axum = "*"
tower = "*"
tower-http = { version = "*", features = ["trace", "timeout", "compression-gzip"] }

[dev-dependencies]
reqwest = { version = "*", features = ["json"] }
```

- `axum` — minimal HTTP framework on top of `tower` and `hyper`.
- `tower-http` — common middleware (request tracing, timeouts,
  compression). Add features as needed; defaults stay light.
- `reqwest` — used by integration tests to hit the locally bound
  server. Not a runtime dependency.

Skip `clap` unless the server takes startup flags. Most servers read
configuration from the environment instead — see *Configuration*
below.

## Source layout

```
src/bin/<name>/
├── main.rs          # Bind, build router, run with graceful shutdown.
├── config.rs        # Env → typed config struct.
├── routes.rs        # Router construction.
└── handlers/        # One module per handler group.
    └── mod.rs
```

Domain logic still lives in the library. Handlers translate HTTP
requests into library calls and library results into HTTP responses.

## Entrypoint pattern

```rust
// src/bin/<name>/main.rs
mod config;
mod handlers;
mod routes;

use std::net::SocketAddr;

use miette::IntoDiagnostic as _;
use tokio::net::TcpListener;
use tokio::signal;
use tracing_subscriber::{EnvFilter, fmt, prelude::*};

#[tokio::main]
async fn main() -> miette::Result<()> {
    miette::set_panic_hook();
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env())
        .init();

    let config = config::load()?;
    let app = routes::build(&config);

    let addr: SocketAddr = config.bind.parse().into_diagnostic()?;
    let listener = TcpListener::bind(addr).await.into_diagnostic()?;
    tracing::info!(%addr, "listening");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .into_diagnostic()?;

    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c().await.expect("install ctrl-c handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => tracing::info!("received SIGINT, shutting down"),
        _ = terminate => tracing::info!("received SIGTERM, shutting down"),
    }
}
```

Notes:

- `shutdown_signal()` returns once either SIGINT or SIGTERM fires.
  `axum::serve(...).with_graceful_shutdown(...)` stops accepting new
  connections and lets in-flight requests finish.
- Distroless containers have no init process. Either rely on this
  in-process signal handling, or wrap the binary in `tini` /
  `docker run --init`. See `dockerfile.md`.

## Error responses

Domain errors derive `thiserror::Error` and `miette::Diagnostic` (per
`scaffolding.md`). Add an `IntoResponse` impl in the binary so
handlers can return `Result<T, AppError>` directly.

```rust
// src/bin/<name>/handlers/error.rs
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde_json::json;

use my_crate::MyError;

pub struct AppError(MyError);

impl From<MyError> for AppError {
    fn from(err: MyError) -> Self {
        Self(err)
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code) = match &self.0 {
            MyError::NotFound(_) => (StatusCode::NOT_FOUND, "not_found"),
            MyError::Validation(_) => (StatusCode::BAD_REQUEST, "validation"),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, "internal"),
        };

        // Log the full diagnostic; respond with code + status only.
        // The diagnostic detail belongs in observability, not in the
        // HTTP response.
        tracing::error!(error = ?self.0, "request failed");

        (status, axum::Json(json!({ "code": code }))).into_response()
    }
}
```

The wrapper is intentional — `IntoResponse` cannot be implemented for
the library's error type from the binary crate (orphan rule), and a
thin wrapper keeps the mapping in one place.

Body content is intentionally minimal. Diagnostic codes, source
spans, and help text leak implementation details — they belong in
logs and traces, not in the HTTP response body.

## Configuration

Punted. Server config conventions are project-dependent. For a quick
default, use `clap` derive with `env` (same as CLIs) so each setting
is documented in `--help` and overridable via env var. Revisit when a
preferred approach is locked in.

## Integration testing

`tests/api.rs` spawns the server on a random port and hits it with
`reqwest`. This catches wiring issues that unit tests miss (missing
routes, middleware misconfiguration, response shape).

```rust
use std::net::SocketAddr;

use reqwest::StatusCode;
use tokio::net::TcpListener;

async fn spawn() -> SocketAddr {
    let app = my_crate::routes::test_router();
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    addr
}

#[tokio::test]
async fn health_returns_200() {
    let addr = spawn().await;
    let res = reqwest::get(format!("http://{addr}/health"))
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
}
```

Domain logic lives in the library and is exercised by hegeltest
property tests (see `property-testing.md`). Integration tests focus
on HTTP plumbing.

## Deploy

Server release is a Docker image build and push.

1. Build the image — see `dockerfile.md` for the cargo-chef +
   distroless template.
2. Tag with the git SHA and a semver / CalVer label.
3. Push to a registry of your choice (skill stays registry-agnostic).
4. Roll out via your orchestrator (Kubernetes, Nomad, ECS, …).

Image tags follow this pattern:

```
ghcr.io/<owner>/<name>:sha-<git-sha>     # immutable
ghcr.io/<owner>/<name>:<calver>          # human-readable
ghcr.io/<owner>/<name>:latest            # rolling pointer
```

CI builds and pushes on every merge to main. The orchestrator pulls
by sha tag for reproducibility; humans read the calver/latest tags
when diagnosing.

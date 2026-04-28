# Rust server Dockerfile

A reusable Dockerfile for Rust HTTP services. Multi-stage build with
`cargo-chef` for dependency caching, plus a distroless runtime image
that ships only the compiled binary and its required shared libraries.

*Adapted from <https://quanttype.net/p/perfect-dockerfile-for-rust-backends/>.*

## Why this shape

- **`cargo-chef` separates dep compilation from source compilation.**
  Touching a `.rs` file invalidates only the source-build layer, not
  the dependency-build layer. Crate compilation dominates Rust build
  time; keeping it cached is the difference between sub-second and
  multi-minute rebuilds.
- **Distroless `cc` base image.** No shell, no package manager, no
  root user. Smaller attack surface, smaller image, and security
  scanners stop flagging the long tail of unrelated CVEs.
- **Cache mounts** keep `~/.cargo/registry`, `~/.cargo/git`, and
  `target/` warm across `docker build` invocations.

## Template

```dockerfile
# syntax=docker/dockerfile:1.7

ARG BINARY_NAME

# 1. Install cargo-chef once, cached.
FROM rust:1.85-slim-bookworm@sha256:<rust-digest> AS chef
WORKDIR /build
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    cargo install cargo-chef --locked

# 2. Plan the dependency build from Cargo.toml + Cargo.lock.
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# 3. Build dependencies first (cached), then the app.
FROM chef AS builder
ARG BINARY_NAME
COPY --from=planner /build/recipe.json recipe.json
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/build/target \
    cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/build/target \
    cargo build --release --bin "$BINARY_NAME" \
    && cp "target/release/$BINARY_NAME" "/build/$BINARY_NAME"

# 4. Final image — distroless cc, nonroot.
FROM gcr.io/distroless/cc-debian13:nonroot@sha256:<distroless-digest> AS runtime
ARG BINARY_NAME
LABEL org.opencontainers.image.source="https://github.com/<owner>/<repo>"
LABEL org.opencontainers.image.licenses="<license>"
COPY --from=builder /build/$BINARY_NAME /usr/local/bin/app
ENTRYPOINT ["/usr/local/bin/app"]
```

The runtime stage hard-codes the destination path (`/usr/local/bin/app`)
and `ENTRYPOINT` — this avoids needing the build arg at runtime and
keeps `docker run <image>` simple.

## Customization points

- `ARG BINARY_NAME` is required. Pass it as `--build-arg
  BINARY_NAME=<name>` or set a default in CI.
- Add `COPY --from=builder /build/<extra>` lines for static assets
  (templates, migrations, etc.) before the `ENTRYPOINT`.
- For data volumes, declare empty directories with `RUN ["mkdir",
  "/data"]` *before* the distroless `USER` change (which `nonroot`
  applies automatically).

## Pinning policy

Always pin base images by SHA digest. A floating tag means today's
`rust:1.85-slim-bookworm` is not tomorrow's, and reproducible builds
quietly stop being reproducible.

```dockerfile
FROM rust:1.85-slim-bookworm@sha256:abcdef… AS chef
```

Refresh digests via Renovate, Dependabot, or a weekly bump — pin once
and let automation maintain the freshness.

Resolve a digest at the command line:

```bash
docker buildx imagetools inspect rust:1.85-slim-bookworm \
  --format '{{json .Manifest.Digest}}'
```

## Signal handling

Distroless has no init process, so PID 1 is your binary. The Linux
kernel ignores SIGINT/SIGTERM for PID 1 unless the process explicitly
installs handlers. Three options, in order of preference:

1. **Handle signals in the binary.** `server.md` shows
   `tokio::signal::ctrl_c()` and `tokio::signal::unix::signal()` for
   SIGTERM. This is the recommended path for first-party services.
2. **`docker run --init`** locally. Docker injects `tini` as PID 1.
3. **Bundle `tini` in the image** for environments that don't pass
   `--init` (some PaaS runtimes). Pull it from the distroless static
   image:

   ```dockerfile
   COPY --from=krallin/tini@sha256:<tini-digest> /tini /tini
   ENTRYPOINT ["/tini", "--", "/usr/local/bin/app"]
   ```

Pick (1) by default — fewer moving parts and consistent behavior in
local, CI, and prod.

## musl / scratch alternative

For a fully static image:

```dockerfile
FROM rust:1.85-slim-bookworm@sha256:… AS chef
RUN rustup target add x86_64-unknown-linux-musl
# ...
RUN cargo build --release --target x86_64-unknown-linux-musl --bin "$BINARY_NAME"

FROM scratch AS runtime
COPY --from=builder /build/<name> /app
ENTRYPOINT ["/app"]
```

Tradeoffs:

- Smaller image (no glibc), no shared libraries to drift.
- musl's allocator is slower than glibc's. Drop in `mimalloc` or
  `jemalloc` if you need the throughput back.
- TLS via `rustls`, not OpenSSL — system roots are not available.
  Bundle `webpki-roots` or vendor a root store.

Distroless is the recommended default. `scratch` is opt-in for
projects that benefit from the size and have validated the runtime
tradeoffs.

## Common pitfalls

- **Forgetting cache mounts** turns every change into a full
  recompile. Verify with `docker build --progress=plain` — you should
  see `CACHED` on the dependency layer when only source files
  changed.
- **Skipping `--locked` on `cargo install`** means cargo-chef's own
  version drifts on rebuild, invalidating its layer.
- **Building without `--release`** ships a debug binary —
  10× slower runtime and ~10× larger.
- **Using `sqlx` macros** without setting `SQLX_OFFLINE=true` and
  committing `sqlx-data.json` will fail at compile time inside the
  builder, where there is no database.
- **Pinning to a tag instead of a digest** breaks reproducibility
  silently; the build keeps working but the bytes change.
- **Copying everything before `cargo chef prepare`** invalidates the
  planner layer on any source change. The recipe is computed from
  Cargo manifests only — keep `COPY . .` in the planner stage but
  trust the recipe layer to capture the dep set.

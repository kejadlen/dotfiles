# Versioning

CLI binaries only. Server versions live on Docker image tags — see
`dockerfile.md` and `server.md` (Deploy).

A `build.rs` sets a single `<NAME>_VERSION` env var. CI sets it to CalVer (`YYYY-MM-DD+SHORT_SHA`); local builds use the same shape but substitute the jj change ID for the git SHA and append `-dev` so they're distinguishable from release builds.

```rust
// build.rs
use std::process::Command;

fn main() {
    let version = std::env::var("<NAME>_VERSION").unwrap_or_else(|_| {
        let date = cmd("date", &["-u", "+%Y-%m-%d"]);
        let change = cmd("jj", &["log", "-r", "@", "--no-graph", "-T", "change_id.short()"]);
        format!("{date}+{change}-dev")
    });
    println!("cargo:rustc-env=<NAME>_VERSION={version}");
}

fn cmd(program: &str, args: &[&str]) -> String {
    Command::new(program)
        .args(args)
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "unknown".into())
}
```

In the binary, read it as a constant and pass it to clap:

```rust
const VERSION: &str = env!("<NAME>_VERSION");

#[derive(Parser)]
#[command(version = VERSION)]
struct Cli { /* ... */ }
```

The release workflow sets the env var during build:

```yaml
      - name: Build
        run: |
          <NAME>_VERSION="${{ steps.version.outputs.version }}" cargo build --release
```

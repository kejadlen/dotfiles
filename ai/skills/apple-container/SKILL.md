---
name: apple-container
description: Use when running Apple's container tool on macOS - covers build, run, exec, and image management commands
---

# Apple Container Tool

macOS container runtime. Not Docker - different syntax for mounts and some flags.

## First-Time Setup

```bash
container system start   # Required before first use, installs kernel
```

## Quick Reference

| Task | Command |
|------|---------|
| Build image | `container build -t name:tag dir/` |
| Run interactive | `container run -it image` |
| Run with name | `container run --name mycontainer image` |
| Run detached | `container run -d --name mycontainer image` |
| List running | `container list` |
| List all | `container list -a` |
| Start stopped | `container start -a container-id` |
| Stop | `container stop container-id` |
| Remove | `container rm container-id` |
| Exec into | `container exec -it container-id bash` |
| Inspect | `container inspect container-id` |

## Mount Syntax

**Different from Docker.** Uses `--mount` with explicit format:

```bash
# Bind mount (host path to container path)
--mount type=bind,src=/host/path,dst=/container/path

# Read-only bind mount
--mount type=bind,src=/host/path,dst=/container/path,readonly

# tmpfs
--tmpfs /path
```

**Not supported:** Docker's `-v /host:/container` shorthand.

## Common Patterns

```bash
# Build and run interactively
container build -t myimage:latest . && container run -it --rm myimage:latest

# Run with project mounted
container run -it --rm \
  --workdir /project \
  --mount type=bind,src=$(pwd),dst=/project \
  myimage:latest

# Named container (persists after exit)
container run -it --name mycontainer myimage:latest
# Later: container start -ai mycontainer

# Check if container exists (inspect returns [] for missing, not error)
[ "$(container inspect mycontainer 2>/dev/null)" != "[]" ] && echo "exists"
```

## Image Management

```bash
container image list              # List local images
container image rm image:tag      # Remove image
container image prune             # Remove dangling images
container image prune -a          # Remove all unused images
```

## Gotchas

- **No `-a` for list by default** - stopped containers hidden without `container list -a`
- **Mount syntax** - must use `--mount type=bind,src=...,dst=...` not `-v`
- **System start required** - run `container system start` before first use
- **Names are IDs** - `--name` sets the container ID, not a separate alias
- **Inspect returns `[]` for missing** - doesn't error like Docker, check output not exit code

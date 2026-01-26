---
name: buildkite
description: Use when needing bk CLI command reference, syntax, or behavior - directs to bk --help for authoritative documentation and flags
---

# Buildkite CLI (bk)

Use `bk --help` for authoritative command reference and current flags.

## Quick Start

Run `bk <command> --help` for detailed command documentation:

```bash
bk --help              # Full command list
bk build view --help   # Specific command details
bk job log --help      # Syntax and options
```

## Core Workflows

**View current build:**
```bash
bk build view          # Current branch's latest build
bk build watch         # Watch build progress in real-time
```

**Work with jobs:**
```bash
bk job list            # List jobs in current build
bk job log <job-id>    # Get job logs
bk job retry <job-id>  # Retry a failed job
```

**Create builds:**
```bash
bk build create        # Trigger new build for current branch
bk build rebuild       # Rebuild a previous build
```

## Command Categories

Run `bk --help` to see all commands. Main categories:

Builds: build view, build list, build create, build watch, build cancel, build rebuild
Jobs: job list, job log, job retry, job cancel, job unblock
Pipelines: pipeline list, pipeline view, pipeline validate, pipeline create
Artifacts: artifacts list, artifacts download
Agents: agent list, agent view, agent pause, agent resume, agent stop
Config: config list, config get, config set, configure add
API: api (direct API calls)

## Global Flags

```bash
-y, --yes        # Skip confirmation prompts
--no-input       # Disable interactive prompts
-q, --quiet      # Suppress progress output
--debug          # Enable debug output for API calls
```

## When to Use bk --help

Direct command help is always more current than documentation. Use it for:

- Exact flag names and syntax
- Current command options
- Command behavior details
- Examples and edge cases

Never rely on this skill's command list as authoritative. Always run `bk <command> --help` to verify behavior, flags, and current options.

# jj pitfalls

Verify anything here against `jj <command> --help`.

## Revsets and filesets

**Avoid revset functions with parentheses.** Claude Code's shell command
parser treats `()` as subshell syntax even when quoted, which triggers
permission prompts. Use the underlying value directly:

```bash
jj log -r trunk                      # correct — paren-free alias
jj log -r 'trunk()'                  # WRONG — triggers permission prompt
```

`trunk` is a config alias for `trunk()`, so it stays correct per repo. Don't
substitute a hardcoded bookmark — `trunk()` resolves differently across
repos, and plenty of them point at something other than `main@origin`.
`jj config get revset-aliases."trunk()"` shows the current repo's value.

**Fileset expressions with special characters need quoting.** Fileset
operators (`,` `~` `|` `&` `()`) in a bare path are parsed as syntax, not
literal characters, so a path like `bin/,z` fails with "Failed to parse
fileset: Syntax error". Wrap the path in a double-quoted string literal —
the shell needs single quotes around it so jj sees the double quotes:

```bash
jj commit -m '...' '".config/foo"' '"bin/,z"'   # literal path with a comma
```

For glob patterns, use `glob:"pattern"` the same way:

```bash
jj diff -- 'glob:"bin/*" ~ glob:"bin/,special"'
```

**Put `-m` before `--` or fileset args.** jj parses everything after `--` as
fileset, so `-m` placed after `--` becomes a parse error.

## Inspecting revisions

**`jj show` does not accept path arguments.** It takes an optional revision
but cannot be scoped to a path. Use `jj diff` instead:

```bash
jj diff -r @-                        # all changes in parent revision
jj diff -r @- path/to/file           # specific file in parent revision
```

**`jj file show` needs `-r`, and silently ignores a revision without it.**
Every positional argument is a path, so `jj file show main@origin FILE`
prints the *working-copy* `FILE` and only warns `No matching entries for
paths: main@origin` — no error, exit status 0:

```bash
jj file show -r main@origin path/to/file    # correct
jj file show main@origin path/to/file       # WRONG — dumps the working-copy version
```

Extracting a "base" copy this way yields a byte-identical duplicate of the
file under test, so any comparison against it passes vacuously. Diff the
extracted copy against the live one before trusting a green result.

**`--no-patch` can't combine with `--summary`/`--stat`/`--name-only`.**
Those flags already suppress the full patch, so adding `--no-patch` errors
out ("cannot be used with"). To see just the changed files, use `--summary`
alone:

```bash
jj show -r @- --summary              # description + file list, no patch
```

**There is no `--cwd` flag.** To target a repo without `cd`ing into it, use
`-R <path>` (short for `--repository`):

```bash
jj log -R /path/to/repo -r main    # correct
jj log --cwd /path/to/repo         # WRONG — no such flag; fails silently
                                    # if stderr is redirected (e.g. `2>/dev/null`)
```

## squash

**It takes its source from `@` unless you pass `--from`.** Naming only
`--into <rev>` and a fileset moves that fileset out of `@`, not out of the
commit you were reading about. When `@` has moved since you last ran `jj
log` — the human committing in another terminal is enough — the squash moves
nothing, yet still prints "Rebased N descendant commits" and gives the
destination a new commit ID, so a no-op looks like it worked. Name the
source and re-check `jj st` immediately before any rewrite:

```bash
jj squash --from <rev> --into <rev> -u FILE   # explicit source
```

**`--from` is repeatable, so collapsing several commits is one rewrite.**
Each `--from` takes a revset and the sources need not be adjacent — commits
in between are rebased, not folded in. Pair it with `-m`, since abandoning
several described sources otherwise opens the editor:

```bash
jj squash --from <rev> --from <rev> --into <rev> -m 'combined message'
```

**It opens `$EDITOR` to merge descriptions and hangs in non-interactive
shells.** When source and destination both have descriptions, jj launches
the editor to combine them — an agent's Bash tool has no TTY, so the
command appears to hang silently and nothing changes. Always pass one of:

```bash
jj squash --use-destination-message   # discard source description
jj squash -u                          # short form
jj squash -m 'new message'            # inline replacement
```

This applies to `jj squash --from X --into Y` too. If you actually want to
merge the two descriptions, do it from a real terminal.

## Tracking

**`jj file untrack` only sticks for paths something already ignores.** It
reports success either way, but jj snapshots the working copy on every
command, so an untracked-but-unignored path is back in `@` the moment any jj
command runs — including one from another terminal or agent. Repeated
untracking of the same path means the ignore rule is missing, not that
untrack failed. Add the path to `.gitignore` or the global ignore first.

With `snapshot.auto-track = "all()"`, a missing global ignore file is enough
to sweep in thousands of files. jj reads it from `core.excludesFile`, falling
back to `$XDG_CONFIG_HOME/git/ignore` — check that path exists before
blaming the repo's `.gitignore`:

```bash
jj config get core.excludesFile     # errors when unset (the common case)
ls ~/.config/git/ignore             # the XDG fallback jj actually reads
```

## Operations

**`jj op undo` has been removed (v0.39+).** Use `jj op revert` or
`jj undo`/`jj redo`.

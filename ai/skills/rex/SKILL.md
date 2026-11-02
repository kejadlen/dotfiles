---
name: rex
description: Use the rex CLI to manage Rex sessions, open tabs, arrange panes, run commands, inspect terminal output, and control connected Rex apps.
metadata:
  rex-stub: "2"
---
<!-- Installed by "rex skill setup". Remove it with "rex skill remove". -->

Run `rex __internal skill` and follow the guide it prints. The guide comes from
the installed Rex CLI, so it describes the commands available in that version.

If the command fails, the installed Rex version predates the guide. Start with
`rex whoami --json`, then use `rex --help` and `rex COMMAND --help`.

## Gotchas

Rex doesn't watch its config: an edit takes effect only after a reload, so a
fixed binding keeps failing the old way until then.

A single syntax error fails the whole config load, and the app silently keeps
the previous keymap — so newly added bindings "do nothing" with no visible
error. When a new binding is dead, run `rex config check` (or compile-check
the Fennel file with the standalone compiler) before debugging the binding
itself. Keys bound to an action by name can also be dead on some builds while
function bindings work; bind a Lua function that calls the API instead.

For floating panes, `session.new_layer` runs its command in a non-interactive
login shell: REX_SESSION and REX_BLOCK are set. A layer's `command` option
is an argv list — the first element is the program's full path, so any
prefix directory belongs string-concatenated into it (`[(.. bin "/,z")]`),
not as its own element, or exec fails with "is a directory". A layer whose
command exits 0 closes itself; on failure it stays open so the error stays
readable. To send the float's result back to the pane that opened it, pass
that pane's `ctx.block_id` into the command and have it `rex block call
write` with `{"data": ...}` — bytes arrive as if typed, no trailing newline,
so text lands on the shell's command line. A focused layer's close does
NOT restore the prior block's focus — the server drops it on another block
in the window — so refocus explicitly: from a surviving process after `rex
wait` (the ctrl+t widget pattern), or from inside the float as its last
action before exit (a synchronous `rex focus` sticks through the layer
teardown; no delay needed). For a pane's context, `process`'s
`foreground.name` (already stripped of login-shell dashes) and `foreground.cwd`
are reliable; `pwd` stays empty until the shell reports via OSC 7. In
`rex keymap`, a Lua-function binding shows as `client.key.forward`.

Compiling is not the same as working: Fennel has no `some`, `find`,
`when-let`, or `label`, and an unknown symbol compiles to a global call that
only fails at runtime. Exercise compiled config functions with `rex do -e
'dofile(...)'` against a live server before shipping them.

A block's shell is a login shell: its PATH comes from profile files, never
.zshrc, so tools put on PATH by an interactive shell setup (z4h, brew in
.zshrc) are missing inside blocks. When a block command needs the caller's
PATH, run it as `["/bin/zsh", "-c", "export PATH=<caller PATH>; exec ..."]`
with `shell: "none"`; `path_prepend` is not applied to directly-run
commands — and that includes the script's *internal* PATH lookups, so a
float script that shells out to dotslash/brew tools needs the wrapper too.

Porting tmux pane scripts: `rex capture --unwrap` matches `capture-pane
-J` (soft wraps joined, natural oldest-to-newest order), and `jq -n --arg
d "$s" '{data:$d}' | rex block call -s S -b B write -` matches `send-keys
-l` (bytes as if typed, no newline; the stdin `-` form keeps quotes and
backslashes safe). Layer commands accept multi-element argv — arguments
after the program path reach it, including `$0`/`$@` after a `sh -c`
wrapper — and a layer runs its command even with no client attached.
`rex wait` on a layer block does not observe its end on every build — one
Mac build burns the full 10s default timeout and exits 0, so a
wait-then-read handoff reads too early every time. Send results out from
inside the float with `write` instead of waiting on the float's block.
A layer command whose argv contains newlines silently executes NOTHING on
some builds (not even the first line, no error anywhere) — keep the
command string one line, statements joined with `;`.

A `rex do` script can read only sessions it has attached to: `block.method`
on another session's block fails with 409 "stream is not attached", and
`--all` doesn't help. Call `rex.call("session.attach", {session_id = ...})`
first; its `.view` is the same snapshot `session.view` returns. A script's
returned string prints JSON-quoted, so `print` rows instead. Agents report
state with OSC 7501, readable per block through the `program_status` method.

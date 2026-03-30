# Resolve conflicts skill

## Scope

A procedural skill that guides conflict resolution after jj
rebase, squash, or merge operations. The skill works in an isolated
child change, attempts automated resolution with mergiraf, then
walks through remaining conflicts file by file.

Not in scope: conflict prevention, upstream sync workflows, bookmark
conflicts, or multi-party merge strategies.

## Audience

Interactive use — the user working with Claude in a terminal session.
Not designed for autonomous subagent use.

## Workflow

### Step 1: Set up the resolution change

The skill accepts an optional `$ARGUMENTS` value — a change ID for the
conflicted revision.

- With argument: run `jj new <change>` to create an empty child change
  on top of the conflicted revision.
- Without argument: run `jj status` to verify the current change is
  empty and its parent has conflicts. If the current change is not
  empty, stop and tell the user to `jj new` first.

All resolution work happens in this child change, keeping the
conflicted revision untouched until the user squashes.

### Step 2: Attempt automated resolution with mergiraf

Run `jj resolve --tool mergiraf -r @-` to attempt structured merge
resolution on the conflicted parent. The `-r @-` flag targets the
parent revision since work happens in the child change.

After mergiraf completes, run `jj resolve --list -r @-` to check for
remaining conflicts. If no conflicts remain, skip to step 4.

### Step 3: Resolve remaining conflicts manually

For each file still listed by `jj resolve --list -r @-`:

1. Read the file to see the conflict markers.
2. Use `jj diff` and context from the parent change to understand both
   sides.
3. Edit the file to resolve the conflict.
4. Move to the next file.

After all files are resolved, run `jj status` to confirm no conflicts
remain.

### Step 4: Prompt to squash

Tell the user the conflicts are resolved and suggest running
`jj squash` to fold the resolution into the parent change. Do not run
the squash — the user controls that step.

## Skill metadata

- Name: `resolve-conflicts`
- Trigger description: "Use when resolving jj conflicts after rebase,
  squash, or merge — handles conflict markers, mergiraf automation,
  and file-by-file manual resolution"
- Argument hint: `[change-id]`
- Allowed tools: `Bash(jj new *)`, `Bash(jj status *)`,
  `Bash(jj resolve *)`, `Bash(jj diff *)`, `Bash(jj log *)`,
  `Bash(jj squash *)` is excluded — the user controls squashing
- Self-improving: yes

## File locations

The skill file goes in both:

- `ai/skills/resolve-conflicts/SKILL.md`
- `ai/claude/skills/resolve-conflicts/SKILL.md`

---
name: gh-projects
description: Use when working with GitHub Projects — listing items, changing status, adding issues or PRs, or looking up project field IDs
---

# GitHub Projects

Quick reference for `gh project` commands on personal projects (`@me`). Run `gh project <command> --help` for full flags.

## The ID Chain

Most `gh project` commands need internal IDs, not human-readable names. Resolve them in order:

### 1. Project number

```
gh project list --owner "@me"
```

Plain tabular output. The first column is the project number.

### 2. Project ID and field IDs

```
gh project field-list <number> --owner "@me" --format json
```

Returns all fields with their IDs and types. Single-select fields (like Status) include an `options` array with option IDs and names:

```json
{
  "id": "PVTSSF_...",
  "name": "Status",
  "options": [
    { "id": "f75ad846", "name": "Backlog" },
    { "id": "47fc9ee4", "name": "In Progress" }
  ],
  "type": "ProjectV2SingleSelectField"
}
```

### 3. Item ID

```
gh project item-list <number> --owner "@me"
```

The last column is the item ID (`PVTI_...`).

### 4. Project global ID

Needed for `item-edit`. Extract from `field-list` or `view` JSON output, or from the fourth column of `gh project list`.

## Common Operations

| Task | Command |
|---|---|
| List items | `gh project item-list <num> --owner "@me"` |
| Add issue/PR | `gh project item-add <num> --owner "@me" --url <issue-url>` |
| Create draft | `gh project item-create <num> --owner "@me" --title "..." --body "..."` |
| Change status | `gh project item-edit --id <item-id> --project-id <project-id> --field-id <field-id> --single-select-option-id <option-id>` |
| Edit text field | `gh project item-edit --id <item-id> --project-id <project-id> --field-id <field-id> --text "..."` |
| Clear field | `gh project item-edit --id <item-id> --project-id <project-id> --field-id <field-id> --clear` |
| View in browser | `gh project view <num> --owner "@me" --web` |

## Batching

Each `gh project` call triggers a permission prompt. Minimize prompts by combining multiple operations into a single Bash call when possible — especially when resolving the ID chain or editing multiple items.

## Gotchas

- `--format json --jq` often fails because the top-level output is an array. Pipe to `jq` instead, or use `--format json` alone and parse with Python.
- `item-edit` only updates one field per invocation. To change status and assignee, run it twice.
- Single-select fields need `--single-select-option-id`, not `--text`. Check the field type in `field-list` output.
- The `--owner` flag defaults to the authenticated user only for some commands. Pass `"@me"` explicitly.

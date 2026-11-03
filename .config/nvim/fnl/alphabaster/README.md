# Alphabaster

A minimal Neovim colorscheme based on [Tonsky's Alabaster philosophy](https://tonsky.me/blog/syntax-highlighting/).

## Philosophy

> If everything is highlighted, nothing stands out. Your eye adapts and considers it a new norm.

Traditional colorschemes assign unique colors to keywords, operators, types, punctuation, variables, functions, and more. The result: visual noise that adds no comprehension value.

Alphabaster highlights only **4 semantic categories**:

| Category | Color | Rationale |
|----------|-------|-----------|
| Comments | Yellow | Important explanations, not noise. The tradition of dimming comments comes from when people were paid by line. |
| Strings | Lavender | Reference points. Logic often starts from string literals. Highlighting also makes unclosed strings obvious. |
| Constants | Lavender | Numbers, booleans, symbols. Also reference points that anchor understanding. |
| Definitions | Cyan | Where functions/types/classes are *defined*, not called. Definitions are rare (~5% of code); calls are everywhere. |

Everything else (keywords, operators, punctuation, variables, function calls) uses the default foreground. This is intentional.

## Color Decisions

### Why not red for comments?

Initial design used red for comments (matching original Alabaster). In practice, red comments looked like errors. Yellow feels like sticky notes — visible but not alarming.

### Why lavender for strings and constants?

Lavender/purple for strings matches the paramount colorscheme, preserving muscle memory. Strings and constants are conceptually similar anyway: literal values that serve as reference points. Using the same color for both simplifies the mental model from 4 categories to 3 visual colors.

### Colors come from the terminal

The colorscheme sets terminal color numbers, not hex values, and `init.fnl` turns `termguicolors` off. Neovim draws with whichever theme the terminal has loaded, so it switches between `~/.config/ghostty/themes/alphabaster` and `alphabaster-light` along with the terminal.

| Role | Slot | Dark | Light |
|---|---|---|---|
| Comments | 8 | `#9BA3C9` | `#5F6480` |
| Strings, constants | 12 | `#D0BCF0` | `#7A4FC4` |
| Definitions | 6 | `#A2D6E0` | `#0A6677` |
| Surfaces (status line, floats, cursor line) | 235 | `#282A36` | `#EEEEEA` |
| Unfocused background | 236 | `#333333` | `#EBEBE6` |
| Selection | 60 | `#626880` | `#DCD6EE` |

Slots 0–15 hold text colors, and none of them works as a fill in both themes, so the theme files also redefine xterm slots 235, 236, and 60. In Rex, turn on Settings › Themes › Use extended theme palette for both modes, or those three fall back to xterm's standard grays.

## File Structure

```
alphabaster/
├── init.fnl      # Highlight definitions
├── palette.fnl   # Color values and semantic mappings
├── lightline.fnl # Statusline theme
└── README.md     # This file
```

Entry point: `colors/alphabaster.lua` (required by `:colorscheme` command)

## Usage

```fennel
(vim.cmd.colorscheme :alphabaster)
```

Or test without changing config:

```vim
:colorscheme alphabaster
```

## Treesitter and LSP

The same 4-category rule applies to Treesitter (`@`-prefixed groups) and LSP semantic tokens (`@lsp.*`). Most groups link to `Normal`; only comments, strings, constants, and definitions get color.

LSP semantic tokens have higher priority (125) than Treesitter (100). We clear most LSP highlights to let Treesitter rules dominate, except for `@lsp.mod.definition` where LSP is more accurate at identifying true definition sites.

## References

- [Tonsky: "I am sorry, but everyone is getting syntax highlighting wrong"](https://tonsky.me/blog/syntax-highlighting/)
- [alabaster.nvim](https://github.com/p00f/alabaster.nvim)
- [vscode-theme-alabaster](https://github.com/tonsky/vscode-theme-alabaster)

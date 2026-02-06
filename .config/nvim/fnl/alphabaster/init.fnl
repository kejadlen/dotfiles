;; fnl/alphabaster/init.fnl
;;
;; Alphabaster: A minimal colorscheme based on Tonsky's Alabaster philosophy.
;; https://tonsky.me/blog/syntax-highlighting/
;;
;; Core insight: If everything is highlighted, nothing stands out.
;; Your eye adapts and considers it a new norm.
;;
;; Only 4 semantic categories get color:
;;   1. Comments   — important explanations, not "visual noise"
;;   2. Strings    — reference points, easy to scan for
;;   3. Constants  — numbers, booleans, symbols (logic starts from constants)
;;   4. Definitions — where functions/types/classes are defined (not called)
;;
;; Everything else (keywords, punctuation, variables, function calls)
;; uses the default foreground. This is intentional.

(local {: colors : semantic} (require :alphabaster.palette))
(local api vim.api)

(fn hi [group opts]
  (api.nvim_set_hl 0 group opts))

(fn link [group target]
  (api.nvim_set_hl 0 group {:link target}))

(fn setup []
  (vim.cmd "highlight clear")
  (set vim.g.colors_name :alphabaster)

  ;;; Base
  (hi :Normal {:fg colors.fg :bg colors.bg})
  (hi :NormalFloat {:fg colors.fg :bg colors.black})
  (hi :FloatBorder {:fg colors.bright-black})

  ;;; === THE 4 SEMANTIC CATEGORIES ===

  ;; Comments are important. The tradition of dimming comments comes from
  ;; when people were paid by line. If code was complex enough to deserve
  ;; an explanation, that explanation should be read first.
  (hi :Comment {:fg semantic.comment})

  ;; Strings are reference points. Logic often starts from string literals.
  ;; Highlighting them also makes unclosed strings immediately obvious.
  (hi :String {:fg semantic.string})

  ;; Constants (numbers, booleans, symbols) are also reference points.
  ;; These anchor your understanding of what code does.
  (hi :Constant {:fg semantic.constant})

  ;; Definitions mark where things are created, not where they're used.
  ;; Function calls are everywhere (~75% of code); definitions are rare
  ;; and worth highlighting.
  (hi :Function {:fg semantic.definition})

  ;;; === DELIBERATELY UNHIGHLIGHTED ===
  ;;
  ;; Keywords, operators, types, etc. are not highlighted.
  ;; They're structural scaffolding — you learn to parse them unconsciously.
  ;; Highlighting them adds noise without aiding comprehension.

  (link :Identifier :Normal)
  (link :Statement :Normal)
  (link :Keyword :Normal)
  (link :Operator :Normal)
  (link :Type :Normal)
  (link :PreProc :Normal)
  (link :Special :Normal)
  (link :Delimiter :Normal)

  ;;; Constants family (all inherit the constant color)
  (link :Number :Constant)
  (link :Boolean :Constant)
  (link :Float :Constant)
  (link :Character :Constant)

  ;;; UI elements
  (hi :Visual {:bg colors.selection-bg :fg colors.selection-fg})
  (hi :CursorLine {:bg colors.black})
  (hi :CursorLineNr {:fg semantic.definition :bg colors.black})
  (hi :LineNr {:fg colors.bright-black})
  (hi :SignColumn {:bg colors.bg})
  (hi :VertSplit {:fg colors.bright-black})
  (hi :WinSeparator {:fg colors.bright-black})
  (hi :StatusLine {:bg colors.black})
  (hi :StatusLineNC {:bg colors.black :fg colors.bright-black})
  (hi :Pmenu {:fg colors.fg :bg colors.black})
  (hi :PmenuSel {:fg colors.fg :bg colors.bright-black})
  (hi :PmenuSbar {:bg colors.black})
  (hi :PmenuThumb {:bg colors.bright-black})
  (hi :TabLine {:fg colors.fg :bg colors.black})
  (hi :TabLineSel {:fg semantic.definition :bg colors.bright-black :bold true})
  (hi :TabLineFill {:bg colors.black})

  ;;; Search — high contrast, needs to pop
  (hi :Search {:fg colors.bg :bg colors.yellow})
  (hi :IncSearch {:fg colors.bg :bg colors.bright-yellow})
  (hi :CurSearch {:fg colors.bg :bg colors.bright-yellow})

  ;;; Diagnostics — these are actionable, worth color
  (hi :DiagnosticError {:fg semantic.error})
  (hi :DiagnosticWarn {:fg semantic.warn})
  (hi :DiagnosticInfo {:fg semantic.info})
  (hi :DiagnosticHint {:fg semantic.hint})
  (hi :DiagnosticUnderlineError {:undercurl true :sp semantic.error})
  (hi :DiagnosticUnderlineWarn {:undercurl true :sp semantic.warn})
  (hi :DiagnosticUnderlineInfo {:undercurl true :sp semantic.info})
  (hi :DiagnosticUnderlineHint {:undercurl true :sp semantic.hint})

  ;;; Diff
  (hi :DiffAdd {:fg semantic.added})
  (hi :DiffDelete {:fg semantic.removed})
  (hi :DiffChange {:fg semantic.changed})
  (hi :DiffText {:fg semantic.changed :bold true})

  ;;; === TREESITTER ===
  ;;
  ;; Treesitter captures use @prefix. We apply the same 4-category rule:
  ;; comments, strings, constants, and definitions get color.
  ;; Everything else inherits Normal.

  ;; Comments
  (link "@comment" :Comment)
  (link "@comment.documentation" :Comment)

  ;; Strings
  (link "@string" :String)
  (link "@string.documentation" :String)
  (link "@string.escape" :Constant)  ;; escape sequences are constants
  (link "@string.regexp" :String)
  (link "@character" :String)

  ;; Constants
  (link "@constant" :Constant)
  (link "@constant.builtin" :Constant)   ;; true, false, nil
  (link "@constant.macro" :Constant)
  (link "@number" :Constant)
  (link "@number.float" :Constant)
  (link "@boolean" :Constant)

  ;; Definitions — only where things are *defined*, not used
  (link "@function" :Normal)              ;; function calls → no highlight
  (link "@function.call" :Normal)
  (link "@function.builtin" :Normal)
  (link "@function.method" :Normal)
  (link "@function.method.call" :Normal)
  (hi "@function.definition" {:fg semantic.definition})
  (hi "@type.definition" {:fg semantic.definition})
  (hi "@variable.definition" {:fg semantic.definition})
  (hi "@parameter" {:fg semantic.definition})  ;; parameter names in signatures

  ;; Deliberately unhighlighted (structural scaffolding)
  (link "@keyword" :Normal)
  (link "@keyword.function" :Normal)
  (link "@keyword.return" :Normal)
  (link "@keyword.operator" :Normal)
  (link "@keyword.conditional" :Normal)
  (link "@keyword.repeat" :Normal)
  (link "@keyword.import" :Normal)
  (link "@keyword.exception" :Normal)
  (link "@operator" :Normal)
  (link "@punctuation" :Normal)
  (link "@punctuation.bracket" :Normal)
  (link "@punctuation.delimiter" :Normal)
  (link "@punctuation.special" :Normal)
  (link "@variable" :Normal)
  (link "@variable.builtin" :Normal)
  (link "@variable.parameter" :Normal)
  (link "@variable.member" :Normal)
  (link "@type" :Normal)
  (link "@type.builtin" :Normal)
  (link "@attribute" :Normal)
  (link "@property" :Normal)
  (link "@field" :Normal)
  (link "@module" :Normal)
  (link "@label" :Normal)
  (link "@tag" :Normal)
  (link "@tag.attribute" :Normal)
  (link "@tag.delimiter" :Normal)

  ;; Markup (for markdown, etc.)
  (link "@markup.heading" :Normal)
  (link "@markup.strong" :Normal)
  (link "@markup.italic" :Normal)
  (link "@markup.link" :Constant)
  (link "@markup.link.url" :String)
  (link "@markup.raw" :String)           ;; code blocks

  ;;; === LSP SEMANTIC TOKENS ===
  ;;
  ;; LSP provides deeper semantic understanding than Treesitter.
  ;; Priority: semantic tokens (125) > treesitter (100).
  ;;
  ;; We mostly clear these to let our Treesitter rules dominate,
  ;; except for definition-related tokens where LSP is more accurate.

  ;; Clear type highlights — we don't want LSP overriding our choices
  (link "@lsp.type.class" :Normal)
  (link "@lsp.type.decorator" :Normal)
  (link "@lsp.type.enum" :Normal)
  (link "@lsp.type.enumMember" :Constant)
  (link "@lsp.type.function" :Normal)
  (link "@lsp.type.interface" :Normal)
  (link "@lsp.type.keyword" :Normal)
  (link "@lsp.type.macro" :Normal)
  (link "@lsp.type.method" :Normal)
  (link "@lsp.type.namespace" :Normal)
  (link "@lsp.type.operator" :Normal)
  (link "@lsp.type.parameter" :Normal)
  (link "@lsp.type.property" :Normal)
  (link "@lsp.type.struct" :Normal)
  (link "@lsp.type.type" :Normal)
  (link "@lsp.type.typeParameter" :Normal)
  (link "@lsp.type.variable" :Normal)

  ;; Strings and comments — let LSP confirm these
  (link "@lsp.type.string" :String)
  (link "@lsp.type.comment" :Comment)

  ;; Definitions — LSP knows exactly where things are defined
  ;; The "definition" modifier marks declaration sites
  (hi "@lsp.mod.definition" {:fg semantic.definition})
  (hi "@lsp.mod.declaration" {:fg semantic.definition})

  ;; Readonly/constant modifiers — these are constants
  (hi "@lsp.mod.readonly" {:fg semantic.constant})
  (hi "@lsp.typemod.variable.readonly" {:fg semantic.constant})
  (hi "@lsp.typemod.property.readonly" {:fg semantic.constant})

  ;; Documentation comments — still comments, still important
  (link "@lsp.type.comment.documentation" :Comment)

  ;;; === PLUGIN SUPPORT ===

  ;; indent-blankline
  ;; Indent guides should be subtle — they're structural, not semantic
  (hi :IblIndent {:fg colors.black})
  (hi :IblScope {:fg colors.bright-black})  ;; current scope slightly brighter

  ;; treesitter-context
  ;; The sticky context header at top of window
  (hi :TreesitterContext {:bg colors.black})
  (hi :TreesitterContextLineNumber {:fg semantic.definition :bg colors.black})

  ;; fidget (LSP progress)
  (hi :FidgetTitle {:fg semantic.definition})
  (hi :FidgetTask {:fg colors.bright-black})

  ;; fzf.vim
  ;; Matched characters should stand out
  (hi :fzf1 {:fg colors.fg :bg colors.black})
  (hi :fzf2 {:fg colors.fg :bg colors.black})
  (hi :fzf3 {:fg colors.fg :bg colors.black})

  ;; dirvish (file browser)
  (link :DirvishPathTail :Normal)
  (hi :DirvishArg {:fg semantic.definition})

  ;; git diff (for fugitive, dirvish-git, etc.)
  (hi :diffAdded {:fg semantic.added})
  (hi :diffRemoved {:fg semantic.removed})
  (hi :diffChanged {:fg semantic.changed})
  (hi :diffFile {:fg semantic.definition})
  (hi :diffLine {:fg colors.bright-black})

  ;; Spelling
  (hi :SpellBad {:undercurl true :sp semantic.error})
  (hi :SpellCap {:undercurl true :sp semantic.info})
  (hi :SpellRare {:undercurl true :sp semantic.hint})
  (hi :SpellLocal {:undercurl true :sp semantic.warn})

  ;; Misc UI
  (hi :MatchParen {:bg colors.bright-black})
  (hi :Folded {:fg colors.bright-black})
  (hi :FoldColumn {:fg colors.bright-black})
  (hi :NonText {:fg colors.bright-black})
  (hi :SpecialKey {:fg colors.bright-black})
  (hi :Whitespace {:fg colors.black})  ;; listchars (tabs, trailing spaces)
  (hi :Directory {:fg semantic.definition})
  (hi :Title {:fg semantic.definition})
  (hi :Question {:fg semantic.info})
  (hi :MoreMsg {:fg semantic.info})
  (hi :WarningMsg {:fg semantic.warn})
  (hi :ErrorMsg {:fg semantic.error :bold true})
  (hi :Todo {:fg semantic.comment :bold true})
  (hi :Underlined {:fg colors.fg :underline true})
  (hi :Ignore {:fg colors.bg})
  (hi :Error {:fg colors.bright-white :bg semantic.error})
  (hi :Conceal {:fg colors.bright-black})
  (hi :CursorColumn {:bg colors.black})
  (hi :ColorColumn {:bg colors.black})
  (hi :QuickFixLine {:bg colors.black}))

{: setup}

;; fnl/alphabaster/palette.fnl
;;
;; Terminal color numbers rather than hex, so Neovim draws with whichever
;; theme the terminal has loaded: ~/.config/ghostty/themes/alphabaster or
;; alphabaster-light. Requires termguicolors off.

(local colors
  {;; ANSI slots
   :red            1
   :green          2
   :yellow         3
   :blue           4
   :magenta        5
   :cyan           6
   :bright-black   8
   :bright-red     9
   :bright-green   10
   :bright-yellow  11
   :bright-blue    12
   :bright-magenta 13
   :bright-cyan    14

   ;; No ANSI slot reads as a fill in both themes, so the theme files redefine
   ;; these xterm slots. Rex needs "Use extended theme palette" on for them.
   :surface      235
   :dim-bg       236  ;; unfocused background (matches tmux pane-focus-out)
   :selection-bg 60})

;; Semantic roles (Alabaster philosophy)
;; Only 4 categories get color. Everything else is default fg.
(local semantic
  {:comment    colors.bright-black ;; visible but secondary
   :string     colors.bright-blue  ;; lavender/purple
   :constant   colors.bright-blue  ;; same as strings — all literal values are lavender
   :definition colors.cyan

   ;; Diagnostics
   :error      colors.red
   :warn       colors.yellow
   :info       colors.cyan
   :hint       colors.bright-magenta

   ;; Diff
   :added      colors.bright-green
   :removed    colors.red
   :changed    colors.bright-blue})

{: colors : semantic}

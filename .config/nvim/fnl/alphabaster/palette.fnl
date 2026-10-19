;; fnl/alphabaster/palette.fnl
;;
;; Color definitions sourced from ~/.config/ghostty/config

;; Ghostty terminal colors (named)
(local colors
  {:bg         "#121218"
   :fg         "#F0F0E4"

   ;; ANSI normal
   :black      "#282A36"
   :red        "#FFB3B3"
   :green      "#7BC275"
   :yellow     "#E6E6A1"
   :blue       "#C4AAEA"
   :magenta    "#E2A6D4"
   :cyan       "#A2D6E0"
   :white      "#F0F0E4"

   ;; ANSI bright
   :bright-black   "#9BA3C9"
   :bright-red     "#FFC9C9"
   :bright-green   "#96D988"
   :bright-yellow  "#EFE9B0"
   :bright-blue    "#D0BCF0"
   :bright-magenta "#EDBBE0"
   :bright-cyan    "#B6E2EA"
   :bright-white   "#FFFFFF"

   ;; Special
   :comment-gray "#A0A0A0"
   :cursor     "#f2d5cf"
   :selection-bg "#626880"
   :selection-fg "#F0F0E4"

   ;; Dimmed background for unfocused windows (matches tmux pane-focus-out)
   :dim-bg     "#333333"})

;; Semantic roles (Alabaster philosophy)
;; Only 4 categories get color. Everything else is default fg.
(local semantic
  {:comment    colors.comment-gray   ;; visible but secondary
   :string     colors.bright-blue ;; lavender/purple
   :constant   colors.bright-blue ;; same as strings — all literal values are lavender
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

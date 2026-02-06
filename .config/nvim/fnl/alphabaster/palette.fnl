;; fnl/alphabaster/palette.fnl
;;
;; Color definitions sourced from ~/.config/ghostty/config

;; Ghostty terminal colors (named)
(local colors
  {:bg         "#121218"
   :fg         "#F0F0E4"

   ;; ANSI normal
   :black      "#282A36"
   :red        "#E97C7C"
   :green      "#7BC275"
   :yellow     "#E6E6A1"
   :blue       "#C4AAEA"
   :magenta    "#E2A6D4"
   :cyan       "#A2D6E0"
   :white      "#F0F0E4"

   ;; ANSI bright
   :bright-black   "#44475A"
   :bright-red     "#F09292"
   :bright-green   "#96D988"
   :bright-yellow  "#EFE9B0"
   :bright-blue    "#D0BCF0"
   :bright-magenta "#EDBBE0"
   :bright-cyan    "#B6E2EA"
   :bright-white   "#FFFFFF"

   ;; Special
   :cursor     "#f2d5cf"
   :selection-bg "#626880"
   :selection-fg "#c6d0f5"})

;; Semantic roles (Alabaster philosophy)
;; Only 4 categories get color. Everything else is default fg.
(local semantic
  {:comment    colors.yellow      ;; warm, like sticky notes (not red — looks like errors)
   :string     colors.blue        ;; lavender/purple
   :constant   colors.blue        ;; same as strings — all literal values are lavender
   :definition colors.cyan

   ;; Diagnostics
   :error      colors.red
   :warn       colors.yellow
   :info       colors.cyan
   :hint       colors.magenta

   ;; Diff
   :added      colors.green
   :removed    colors.red
   :changed    colors.blue})

{: colors : semantic}

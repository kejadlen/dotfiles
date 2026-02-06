;; fnl/alphabaster/lightline.fnl
;;
;; Lightline theme for alphabaster.
;; Minimal: same philosophy as the colorscheme.

(local {: colors : semantic} (require :alphabaster.palette))

;; Lightline expects: [fg, bg, cterm_fg, cterm_bg]
;; We only use GUI colors, so cterm values are placeholders.
(fn ll [fg bg]
  [fg bg 0 0])

(local normal   (ll colors.fg colors.black))
(local inactive (ll colors.bright-black colors.black))
(local insert   (ll colors.bg semantic.string))
(local visual   (ll colors.bg colors.selection-bg))
(local replace  (ll colors.bg semantic.error))

;; Middle section is transparent (matches your current config)
(local middle [[:NONE :NONE :NONE :NONE]])

(local palette
  {:normal  {:left [normal normal] :middle middle :right [normal normal]}
   :insert  {:left [insert normal] :middle middle :right [normal normal]}
   :visual  {:left [visual normal] :middle middle :right [normal normal]}
   :replace {:left [replace normal] :middle middle :right [normal normal]}
   :inactive {:left [inactive inactive] :middle middle :right [inactive inactive]}
   :tabline {:left [normal] :tabsel [insert] :middle middle :right [normal]}})

;; Register with lightline
(fn setup []
  (tset vim.g "lightline#colorscheme#alphabaster#palette" palette))

{: setup : palette}

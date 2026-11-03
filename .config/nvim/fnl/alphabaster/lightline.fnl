;; fnl/alphabaster/lightline.fnl
;;
;; Lightline theme for alphabaster.
;; Minimal: same philosophy as the colorscheme.

(local {: colors : semantic} (require :alphabaster.palette))

;; Lightline expects: [gui_fg, gui_bg, cterm_fg, cterm_bg, attr]
;; The palette is cterm slots, so the GUI values are placeholders.
(fn ll [fg bg ?attr]
  [:NONE :NONE fg bg ?attr])

;; Reversing an accent paints it behind text in the terminal's background.
(fn accent [color]
  (ll color :NONE :reverse))

(local normal   (ll :NONE colors.surface))
(local inactive (ll semantic.comment colors.surface))
(local insert   (accent semantic.string))
(local visual   (ll :NONE colors.selection-bg))
(local replace  (accent semantic.error))

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

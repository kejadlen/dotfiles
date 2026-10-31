(local terminal :com.superlogical.terminal)

;; Programs that handle ctrl+hjkl themselves, after vim-tmux-navigator's list.
(local navigator-aware {:vi true :vim true :nvim true :view true
                        :vimdiff true :nvimdiff true :fzf true})

(fn navigate [direction]
  (fn [ctx]
    (let [p (and ctx.block_id
                 (rex.block.call terminal :process {:block_id ctx.block_id}))
          name (?. p :foreground :name)]
      (if (and name (. navigator-aware (name:match "[^/]+$")))
          false
          (do
            (rex.session.focus_direction {: direction})
            true)))))

(each [key direction (pairs {:h :left :j :down :k :up :l :right})]
  (rex.bind (.. :ctrl+ key) (navigate direction)))

(rex.bind :ctrl+b>v :pane.split {:direction :right})
(rex.bind :ctrl+b>s :pane.split {:direction :down})
(rex.bind :ctrl+b>z :pane.zoom)
(rex.bind :ctrl+b>x :pane.close)

;; The block offset places away from block-id in its layer's order, if any.
;; Scans until it matches because swap-pane is called between reads: without
;; the early exit the same block can match again after it moves.
(fn neighbor-block [session-id block-id offset]
  (var hit nil)
  (let [view (rex.session.view {:session_id session-id})]
    (each [_ window (ipairs (or view.windows [])) :until hit]
      (each [_ layer (ipairs (or window.layers [])) :until hit]
        (let [blocks (or layer.blocks [])]
          (each [i block (ipairs blocks) :until hit]
            (when (= block.block_id block-id)
              (set hit (?. blocks (+ i offset) :block_id))))))))
  hit)

;; tmux muscle memory: swap the focused pane with the previous or next one.
;; Focus follows the pane to its new place.
(fn swap-pane [offset]
  (fn [ctx]
    (let [other (neighbor-block ctx.session_id ctx.block_id offset)]
      (when other
        (rex.session.swap_blocks {:session_id ctx.session_id
                                  :block_id ctx.block_id
                                  :other_block_id other})))
    true))

(rex.bind "ctrl+b>shift+[" (swap-pane -1))
(rex.bind "ctrl+b>shift+]" (swap-pane 1))

(each [_ mod (ipairs ["" :ctrl+])]
  (rex.bind (.. :ctrl+b> mod :c) :client.tab.new)
  (rex.bind (.. :ctrl+b> mod :n) :client.tab.next)
  (rex.bind (.. :ctrl+b> mod :p) :client.tab.previous))

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

(local bin (.. (os.getenv :HOME) "/.dotfiles/bin"))

;; Rex's PATH lacks brew and nix, so the dotslash-wrapped tools (zoxide, fzf, jq)
;; can't exec; the float runs the script with an explicit PATH instead.
;; TODO: Drop this if new_layer gains the --interactive option from Rex af0c204.
(fn with-path [script ...]
  ["/bin/zsh" "-c"
   "export PATH=\"$HOME/.dotfiles/bin:$HOME/.nix-profile/bin:/opt/homebrew/bin:$PATH\"; exec \"$0\" \"$@\""
   script ...])

;; Centered at 80% x 60%, the same box as the tmux floating panes.
(fn float [label script ...]
  (rex.session.new_layer
    {:bounds [0.1 0.2 0.8 0.6]
     :focus true
     :layout (rex.layout.block
               {:flavor :com.superlogical.terminal.shell
                : label
                :options {:command (with-path script ...) :shell "none"}})}))

(fn zoxide [] (float :zoxide (.. bin "/,z")))
(rex.action {:name :zoxide :title "Open Directory in New Session" :run zoxide})
;; Keys bound to a custom action by name do nothing in Rex Beta 1696, though
;; the palette runs it, so the key calls the function directly.
(rex.bind :ctrl+b>g #(do (zoxide) true))

;; Scrollback token grabber, the same float as tmux's Tab binding. "--rex
;; SESSION BLOCK" tells ,tmux-grab to capture and write back through the rex
;; API instead of tmux, targeting the pane that opened the float.
(fn grab []
  (fn [ctx]
    (float :grab (.. bin "/,tmux-grab") "--rex" ctx.session_id ctx.block_id)
    ;; Without true, the Tab also reaches the pane and opens z4h's completion.
    true))

(rex.bind :ctrl+b>tab (grab))

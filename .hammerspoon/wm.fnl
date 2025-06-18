;; Ported from https://github.com/miromannino/miro-windows-manager/blob/master/MiroWindowsManager.spoon/init.lua#L95-L121

(local {:fnutils {:indexOf index-of} : grid : logger : window} hs)
(local {: with-ax-hotfix} (require :utils))

(local log (logger.new :wm :info))

;; fnlfmt: skip
(local steps (let [full           {:x 0 :y 0 :w 8 :h 8}
                   three-quarters {:x 1 :y 1 :w 6 :h 6}
                   half           {:x 2 :y 2 :w 4 :h 4}]
               [full three-quarters half]))

(λ init []
  (grid.setGrid :8x8)
  (grid.setMargins "0,0"))

(λ step []
  (when (window.focusedWindow)
    (let [win (window.frontmostWindow)
          screen (win:screen)
          cell (grid.get win screen)
          next-step-index (-> (index-of steps cell)
                              (or -1)
                              (% (length steps))
                              (+ 1))
          next-step (. steps next-step-index)]
      (with-ax-hotfix win #(grid.set win next-step screen)))))

{: init : step}

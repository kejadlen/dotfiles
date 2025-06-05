;; Ported from https://github.com/miromannino/miro-windows-manager/blob/master/MiroWindowsManager.spoon/init.lua#L95-L121

(local {:fnutils {:indexOf index-of}} hs)

(local log (hs.logger.new :init :info))

(local full {:x 0 :y 0 :w 8 :h 8})
(local three-quarters {:x 1 :y 1 :w 6 :h 6})
(local half {:x 2 :y 2 :w 4 :h 4})
(local steps [full three-quarters half])

(λ init []
  (hs.grid.setGrid :8x8)
  (hs.grid.setMargins "0,0"))

(λ step []
  (when (hs.window.focusedWindow)
    (let [win (hs.window.frontmostWindow)
          screen (win:screen)
          cell (hs.grid.get win screen)
          next-step-index (-> (index-of steps cell)
                              (or -1)
                              (% (length steps))
                              (+ 1))
          next-step (. steps next-step-index)]
      (hs.grid.set win next-step screen))))

{: init : step}

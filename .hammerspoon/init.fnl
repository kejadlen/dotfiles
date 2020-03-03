(let [mash [:cmd :alt :ctrl]
      smash [:cmd :alt :ctrl :shift]
      wm {:left hs.layout.left50
          :right hs.layout.right50
          :ne [ 0.5 0 0.5 0.5 ]
          :nw [ 0 0 0.5 0.5 ]
          :se [ 0.5 0.5 0.5 0.5 ]
          :sw [ 0 0.5 0.5 0.5 ]
          :max hs.layout.maximized}
      move (fn [key] (let [win (hs.window.focusedWindow)
                           geo (. wm key)]
                       (win:move geo nil true)))]
  (hs.hotkey.bind mash "h" (fn [] (move :left)))
  (hs.hotkey.bind mash "l" (fn [] (move :right)))
  (hs.hotkey.bind mash "m" (fn [] (move :max))))

(local {: run : with-ax-hotfix} (require :utils))

(local log (hs.logger.new :little-ff :info))

(local ff {:bin "/Applications/Firefox\\ Developer\\ Edition.app/Contents/MacOS/firefox"
           :bundle-id :org.mozilla.firefoxdeveloperedition
           :name "Firefox Developer Addition"})

(local glide {:bin :/Applications/Glide.app/Contents/MacOS/glide
              :bundle-id :app.glide-browser.glide
              :name :Glide})

(local browser glide)

(λ is-ff-focused []
  (let [win (hs.window.focusedWindow)
        bundle-id (-> win
                      (: :application)
                      (: :bundleID))]
    (if (= bundle-id browser.bundle-id)
        win)))

(λ check-ff [cb]
  (let [win (is-ff-focused)]
    (if win (cb win) (log:w "Firefox not focused"))))

(λ resize-little-ff []
  (check-ff (fn [win]
              (let [hide-sidebar #(hs.eventtap.keyStroke [:ctrl] :z)]
                (with-ax-hotfix win
                  #(win:moveToUnit "[20,10,80,90]"))
                (hide-sidebar)))))

(λ wait-for-little-ff [cb]
  (let [timer (hs.timer.waitUntil is-ff-focused cb 0.05)]
    (hs.timer.doAfter 1 #(timer:stop))))

(λ open [url]
  (let [cmd (table.concat [browser.bin :--new-window (.. "\"" url "\"")] " ")]
    (log:d "Executing:" cmd)
    (hs.execute cmd)
    (wait-for-little-ff resize-little-ff)))

(λ rehome []
  (let [win (is-ff-focused)
        num-windows (-?> win
                         (: :application)
                         (: :allWindows)
                         (length))]
    (when (and num-windows (< 1 num-windows))
      (hs.eventtap.keyStroke [] :escape)
      (hs.eventtap.keyStrokes :yy)
      (hs.pasteboard.callbackWhenChanged #(do
                                            (win:close)
                                            (run (table.concat [:open
                                                                :-a
                                                                (.. "\""
                                                                    browser.name
                                                                    "\"")
                                                                (hs.pasteboard.readString)]
                                                               " "))
                                            ;; TODO figure out how to focus the main
                                            ;; ff window - aerospace doesn't seem to
                                            ;; handle the programmatic closing of the
                                            ;; little ff window all that well
                                            )))))

{: open : rehome : is-ff-focused}

(local {: with-ax-hotfix} (require :utils))

(local log (hs.logger.new :little-ff :info))

(local ff-bin
       "/Applications/Firefox\\ Developer\\ Edition.app/Contents/MacOS/firefox")

(local ff-bundle-id :org.mozilla.firefoxdeveloperedition)

(λ is-ff-focused []
  (let [win (hs.window.focusedWindow)
        bundle-id (-> win
                      (: :application)
                      (: :bundleID))]
    (if (= bundle-id ff-bundle-id)
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
  (hs.execute (table.concat [ff-bin :--new-window (.. "\"" url "\"")] " "))
  (wait-for-little-ff resize-little-ff))

(λ rehome []
  (let [win (is-ff-focused)
        num-windows (-?> win
                         (: :application)
                         (: :allWindows)
                         (length))]
    (when (< 1 num-windows)
      (hs.eventtap.keyStroke [] :escape)
      (hs.eventtap.keyStrokes :yy)
      (hs.pasteboard.callbackWhenChanged #(do
                                            (win:close)
                                            (hs.eventtap.keyStroke [:shift] :p)
                                            ;; TODO figure out how to move the tab to
                                            ;; the back - this doesn't seem to work,
                                            ;; maybe create a custom tridactyl bind?
                                            ;;
                                            ;; (hs.eventtap.keyStroke [] :escape)
                                            ;; (hs.eventtap.keyStrokes ":tabmove $")
                                            ;; (hs.eventtap.keyStroke [] :enter)
                                            ;;
                                            ;; TODO figure out how to focus the main
                                            ;; ff window - aerospace doesn't seem to
                                            ;; handle the programmatic closing of the
                                            ;; little ff window all that well
                                            )))))

{: open : rehome : is-ff-focused}

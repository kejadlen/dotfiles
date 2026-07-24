(local {: chomp : with-ax-hotfix} (require :utils))

(local log (hs.logger.new :little-ff :info))

(local aerospace :/opt/homebrew/bin/aerospace)

(local ff {:bin "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox"
           :bundle-id :org.mozilla.firefoxdeveloperedition
           :name "Firefox Developer Addition"})

(local glide {:bin :/Applications/Glide.app/Contents/MacOS/glide
              :bundle-id :app.glide-browser.glide
              :name :Glide})

(local browser glide)

(λ is-ff-focused []
  ;; focusedWindow returns nil when nothing is focused, which happens often
  ;; enough while polling for a window that is still being created.
  (let [win (hs.window.focusedWindow)
        app (when win (win:application))
        bundle-id (when app (app:bundleID))]
    (when (= bundle-id browser.bundle-id)
      win)))

(λ check-ff [cb]
  (let [win (is-ff-focused)]
    (if win (cb win) (log:w "Firefox not focused"))))

;; Never run these synchronously. Opening a URL activates Hammerspoon, and
;; aerospace answers an activation by querying the app over the accessibility
;; API. A blocking hs.execute deadlocks the two — aerospace waits on
;; Hammerspoon's main thread while Hammerspoon waits on aerospace — until
;; aerospace's 3 second AX timeout fires, once per call.
(λ aerospace-run [args cb]
  (: (hs.task.new aerospace (fn [rc out err]
                              (if (= rc 0)
                                  (cb (chomp out))
                                  (do
                                    (log:w :aerospace (table.concat args " ")
                                           "failed:"
                                           (chomp (if (= err "") out err)))
                                    (cb nil))))
                  args) :start))

(λ focused-workspace [cb]
  "Calls `cb` with the name of the focused aerospace workspace, or nil"
  (aerospace-run [:list-workspaces :--focused] cb))

(λ move-to-workspace [win workspace cb]
  (aerospace-run [:move-node-to-workspace
                  :--focus-follows-window
                  :--window-id
                  (tostring (win:id))
                  "--"
                  workspace] cb))

(λ resize-little-ff []
  (check-ff (fn [win]
              (let [hide-sidebar #(hs.eventtap.keyStroke [:ctrl] :z)]
                (with-ax-hotfix win
                  #(win:moveToUnit "[20,10,80,90]"))
                (hide-sidebar)))))

(λ place-little-ff [workspace]
  "Moves the new window back to `workspace`, then sizes it.

  Launching the browser activates the app, which pulls aerospace over to
  whatever workspace the browser already lives on, so the new window is born
  there rather than where the URL was opened from."
  (check-ff (fn [win]
              (let [before (win:screen)
                    ;; moveToUnit sizes against the window's current screen, so
                    ;; give the window a beat when the move crossed monitors.
                    finish (fn []
                             (if (= (: (win:screen) :id) (before:id))
                                 (resize-little-ff)
                                 (hs.timer.doAfter 0.1 resize-little-ff)))]
                (if workspace
                    (move-to-workspace win workspace finish)
                    (finish))))))

;; A cold browser can take several seconds to put the new window on screen.
;; Give up eventually so a failed launch doesn't leave a timer polling forever.
(local window-timeout 10)

(λ wait-for-little-ff [cb]
  (let [timer (hs.timer.waitUntil is-ff-focused cb 0.05)]
    (hs.timer.doAfter window-timeout
                      #(when (timer:running)
                         (log:w "Gave up waiting for the window after"
                                window-timeout :seconds)
                         (timer:stop)))))

(λ open [url]
  ;; Read the workspace before launching: activating the browser moves
  ;; aerospace's focus to wherever the browser already has windows.
  (focused-workspace (fn [workspace]
                       (let [args [:--new-window url]]
                         (log:d "Launching:" browser.bin
                                (table.concat args " "))
                         (: (hs.task.new browser.bin nil args) :start)
                         (wait-for-little-ff #(place-little-ff workspace))))))

{: open : is-ff-focused}

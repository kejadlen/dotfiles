(local {: chomp : with-ax-hotfix} (require :utils))

(local log (hs.logger.new :little-ff :info))

(local aerospace :/opt/homebrew/bin/aerospace)

(local browser (let [_ff {:bin "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox"
                          :bundle-id :org.mozilla.firefoxdeveloperedition
                          :name "Firefox Developer Addition"}
                     glide {:bin :/Applications/Glide.app/Contents/MacOS/glide
                            :bundle-id :app.glide-browser.glide
                            :name :Glide}]
                 glide))

(λ focused-browser-window []
  ;; -?> because focusedWindow returns nil when nothing is focused, which
  ;; happens often while polling for a window that is still being created.
  (let [win (hs.window.focusedWindow)]
    (match (-?> win
                (: :application)
                (: :bundleID))
      browser.bundle-id win)))

;; Never run these synchronously. Opening a URL activates Hammerspoon, and
;; aerospace answers an activation by querying the app over the accessibility
;; API. A blocking hs.execute deadlocks the two — aerospace waits on
;; Hammerspoon's main thread while Hammerspoon waits on aerospace — until
;; aerospace's 3 second AX timeout fires, once per call.
(λ aerospace-run [args cb]
  "Calls `cb` with aerospace's output, or nil when it fails"
  (let [on-exit (fn [rc out err]
                  (if (= rc 0)
                      (cb (chomp out))
                      (do
                        (log:w :aerospace (table.concat args " ") "failed:"
                               (chomp err))
                        (cb))))]
    (: (hs.task.new aerospace on-exit args) :start)))

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

(λ resize-little-ff [win]
  (let [hide-sidebar #(hs.eventtap.keyStroke [:ctrl] :z)]
    (with-ax-hotfix win
      #(win:moveToUnit "[20,10,80,90]"))
    (hide-sidebar)))

(λ place-little-ff [win workspace]
  "Moves `win` to `workspace`, then sizes it.

  Launching the browser activates the app, which pulls aerospace over to
  whatever workspace the browser already lives on, so the new window is born
  there rather than where the URL was opened from."
  (let [before (win:screen)
        ;; moveToUnit sizes against the window's current screen, so give the
        ;; window a beat when the move crossed monitors.
        resize #(if (= (: (win:screen) :id) (before:id))
                    (resize-little-ff win)
                    (hs.timer.doAfter 0.1 #(resize-little-ff win)))]
    (if workspace
        (move-to-workspace win workspace resize)
        (resize))))

;; A cold browser can take several seconds to put the new window on screen.
;; Give up eventually so a failed launch doesn't leave a timer polling forever.
(local window-timeout 10)

(λ wait-for-little-ff [cb]
  "Calls `cb` with the browser window once it is focused"
  (let [on-focus #(let [win (focused-browser-window)]
                    (if win
                        (cb win)
                        (log:w "Lost the window before placing it")))
        timer (hs.timer.waitUntil focused-browser-window on-focus 0.05)]
    (hs.timer.doAfter window-timeout
                      #(when (timer:running)
                         (log:w "Gave up waiting for a" browser.name
                                "window after" window-timeout :seconds)
                         (timer:stop)))))

(λ open [url]
  ;; Read the workspace before launching: activating the browser moves
  ;; aerospace's focus to wherever the browser already has windows.
  (focused-workspace (fn [workspace]
                       (log:d :Launching browser.name :with url)
                       (: (hs.task.new browser.bin nil [:--new-window url])
                          :start)
                       (wait-for-little-ff #(place-little-ff $1 workspace)))))

{: open : focused-browser-window}

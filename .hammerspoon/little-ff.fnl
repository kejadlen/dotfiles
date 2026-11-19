(local {: chomp : with-ax-hotfix} (require :utils))

(local log (hs.logger.new :little-ff :info))

(local omniwmctl (.. (os.getenv :HOME) :/.nix-profile/bin/omniwmctl))

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

;; Never run these synchronously. Opening a URL activates Hammerspoon, and a
;; window manager answers an activation by querying the app over the
;; accessibility API. A blocking hs.execute deadlocks the two until the
;; window manager's AX timeout fires.
(λ omniwm-run [args cb]
  "Calls `cb` with omniwmctl's output, or nil when it fails"
  (let [on-exit (fn [rc out err]
                  (let [out (chomp (.. out err))]
                    (if (or (= rc 0) (out:find :no_change 1 true))
                        (cb out)
                        (do
                          (log.w :omniwmctl (table.concat args " ") "failed:"
                                 out)
                          (cb)))))]
    (: (hs.task.new omniwmctl on-exit args) :start)))

(λ omniwm-query [args cb]
  "Calls `cb` with the query's decoded payload, or nil when it fails"
  (omniwm-run (doto (icollect [_ a (ipairs args) &into [:query]] a)
                (table.insert :--format)
                (table.insert :json))
              #(cb (-?> $1 (hs.json.decode) (?. :result :payload)))))

(λ focused-workspace [cb]
  "Calls `cb` with the name of the focused omniwm workspace, or nil"
  (omniwm-query [:active-workspace] #(cb (?. $1 :workspace :rawName))))

(λ omniwm-window [win cb]
  "Calls `cb` with omniwm's record for `win`, or nil"
  (omniwm-query [:windows
                 :--bundle-id
                 browser.bundle-id
                 :--fields
                 "id,window-id,mode"]
              (fn [payload]
                (cb (accumulate [found nil _ w (ipairs (or (?. payload
                                                               :windows)
                                                           []))
                                 &until found]
                      (when (= w.windowId (win:id)) w))))))

(λ resize-little-ff [win]
  (let [hide-sidebar #(hs.eventtap.keyStroke [:ctrl] :z)]
    (with-ax-hotfix win
      #(win:moveToUnit "[20,10,80,90]"))
    (hide-sidebar)))

(λ float [ow-win cb]
  "Floats `ow-win` so omniwm won't tile it"
  ;; omniwm can only toggle the focused window, so confirm it's still ours.
  (if (= ow-win.mode :floating)
      (cb)
      (omniwm-query [:windows :--focused :--fields :id]
                    #(if (= (?. $1 :windows 1 :id) ow-win.id)
                         (omniwm-run [:command :toggle-focused-window-floating]
                                     cb)
                         (do
                           (log.w "Focus moved off the new window; not floating it")
                           (cb))))))

(λ move-and-focus [ow-win workspace cb]
  ;; Navigating follows the window, so the sidebar keystroke lands on it.
  (omniwm-run [:window :move-to-workspace ow-win.id workspace]
              #(omniwm-run [:window :navigate ow-win.id] cb)))

(λ place-little-ff [win ?workspace]
  "Moves `win` to `?workspace`, floats it, then sizes it.

  Launching the browser activates the app, which can pull the window manager
  over to whatever workspace the browser already lives on, so the new window
  is born there rather than where the URL was opened from."
  (let [before (win:screen)
        ;; moveToUnit sizes against the window's current screen, so give the
        ;; window a beat when the move crossed monitors.
        resize #(if (= (: (win:screen) :id) (before:id))
                    (resize-little-ff win)
                    (hs.timer.doAfter 0.1 #(resize-little-ff win)))]
    (omniwm-window win
                   (fn [ow-win]
                     (if (not ow-win)
                         (do
                           (log.w "omniwm isn't managing window" (win:id))
                           (resize))
                         ;; Always move: a just-born window may not report
                         ;; its workspace yet.
                         ?workspace
                         (float ow-win
                                #(move-and-focus ow-win ?workspace resize))
                         (float ow-win resize))))))

;; A cold browser can take several seconds to put the new window on screen.
;; Give up eventually so a failed launch doesn't leave a timer polling forever.
(local window-timeout 10)

(λ wait-for-little-ff [cb]
  "Calls `cb` with the browser window once it is focused"
  (let [on-focus #(let [win (focused-browser-window)]
                    (if win
                        (cb win)
                        (log.w "Lost the window before placing it")))
        timer (hs.timer.waitUntil focused-browser-window on-focus 0.05)]
    (hs.timer.doAfter window-timeout
                      #(when (timer:running)
                         (log.w "Gave up waiting for a" browser.name
                                "window after" window-timeout :seconds)
                         (timer:stop)))))

(λ open [url]
  ;; Read the workspace before launching: activating the browser can move the
  ;; window manager's focus to wherever the browser already has windows.
  (focused-workspace (fn [?workspace]
                       (log.d :Launching browser.name :with url)
                       (: (hs.task.new browser.bin nil [:--new-window url])
                          :start)
                       (wait-for-little-ff #(place-little-ff $1 ?workspace)))))

{: open : focused-browser-window}

(local log (hs.logger.new "log" "info"))

(set hs.window.animationDuration 0.0)
(hs.loadSpoon "MiroWindowsManager")
;; (set spoon.MiroWindowsManager.fullScreenSizes [1 (/ 4 3) 2]) ;; only fullscreen
(let [mash [:cmd :alt :ctrl]
      smash [:cmd :alt :ctrl :shift]]
  (spoon.MiroWindowsManager:bindHotkeys {
    :up         [ mash  "k" ]
    :left       [ mash  "h" ]
    :down       [ mash  "j" ]
    :right      [ mash  "l" ]
    :fullscreen [ mash  "m" ]
    ;; :center     [ mash  "c" ]
    ;; :move       [ smash "m" ]
    ;; :resize     [ mash  "d" ]
  }))

(let [mash [:cmd :alt :ctrl]
      smash [:cmd :alt :ctrl :shift]]

  ;; debugging
  ;; (hs.hotkey.bind mash "d" (fn []))

  ;; defeat paste blocking
  (hs.hotkey.bind [:cmd :alt] "v" (fn [] (hs.eventtap.keyStrokes (hs.pasteboard.getContents)))))

(set hs.logger.defaultLogLevel "info")

(set hs.urlevent.httpCallback
  (fn [scheme host params fullURL]
    (let [command (.. "curl -Ls -o /dev/null -w %{url_effective} " fullURL)
          handle (io.popen command)
          url (handle:read "*a")]
      (if (string.find url "^https?://.*[.]zoom.us/j/%d+")
          (hs.urlevent.openURLWithBundle fullURL "us.zoom.xos")
          (hs.urlevent.openURLWithBundle fullURL "org.mozilla.firefoxdeveloperedition")))))

;; Spoons

(hs.loadSpoon "ReloadConfiguration")
(spoon.ReloadConfiguration:start)

(hs.loadSpoon "Quitter")
(set spoon.Quitter.quitAppsAfter {
  :Discord      300
  :Flotato      300
  :MailMate     600
  :Messages     300
  :Reeder       600
  :Slack        300
  :Telegram     300
  :Twitterrific 300
})
(spoon.Quitter:start)

(let [n (hs.notify.new {
           :title "Hammerspoon"
           :informativeText "Config loaded"
           :withdrawAfter 2
         })]
  (n:send))

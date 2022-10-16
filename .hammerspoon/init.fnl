(local log (hs.logger.new :log :info))
(set hs.logger.defaultLogLevel :info)

(local mash [:cmd :alt :ctrl])
(local smash [:cmd :alt :ctrl :shift])

(set hs.window.animationDuration 0.0)
(hs.loadSpoon :MiroWindowsManager)
;; (set spoon.MiroWindowsManager.fullScreenSizes [1 (/ 4 3) 2]) ; only fullscreen

;; fnlfmt: skip
(spoon.MiroWindowsManager:bindHotkeys {:up         [mash :k]
                                       :left       [mash :h]
                                       :down       [mash :j]
                                       :right      [mash :l]
                                       :fullscreen [mash :m]
                                       ;; :center  [mash  "c"]
                                       ;; :move    [smash "m"]
                                       ;; :resize  [mash  "d"]
                                       })

;; debugging
;; (hs.hotkey.bind mash "d" (fn []))
;; (hs.hotkey.bind mash "d" (fn [] (hs.dialog.blockAlert "message" "text" "one" "two")))
;; (hs.hotkey.bind mash "d" (fn [] (hs.dialog.alert 100 100 (fn [] ) "message" "text" "one" "two")))

;; defeat paste blocking
(hs.hotkey.bind [:cmd :alt] :v
                #(hs.eventtap.keyStrokes (hs.pasteboard.getContents)))

(hs.hotkey.bind mash :e
                #(let [app (hs.application.frontmostApplication)
                       prev-pasteboard (hs.pasteboard.getContents)
                       e (hs.uielement.focusedElement)
                       text (if e (e:selectedText)
                                (do
                                  (hs.eventtap.keyStroke [:cmd] :c)
                                  (hs.pasteboard.getContents)))
                       date (hs.execute "date -Iseconds -u | tr -d '\n'")
                       file (.. "~/.quickcursor." date)]
                   (hs.pasteboard.setContents text)
                   (hs.execute (.. "pbpaste > " file))
                   (hs.execute (.. "/opt/homebrew/bin/mvim --nofork " file))
                   (hs.execute (.. "pbcopy < " file))
                   (app:setFrontmost)
                   (hs.eventtap.keyStroke [:cmd] :v)
                   (hs.execute (.. "rm " file))
                   (hs.pasteboard.setContents prev-pasteboard)))

;; https://stackoverflow.com/questions/39464668/how-to-get-bundle-id-of-mac-application
;;   osascript -e 'id of app "SomeApp"'
;;   mdls -name kMDItemCFBundleIdentifier -r SomeApp.app

;; fnlfmt: skip
(local bundle-ids {:firefox :org.mozilla.firefoxdeveloperedition
                   :safari  :com.apple.Safari
                   :zoom    :us.zoom.xos})

(fn handle [url orig-url]
  (let [open-with (fn [app]
                    (partial #(hs.urlevent.openURLWithBundle $2 $1)
                             (. bundle-ids app)))
        open-url #((open-with $1) url)]
    (if (url:find "^https://.*[.]zoom.us/j/%d+") (open-url :zoom)
        (url:find "^https://.*[.]discnw.org/") (open-url :safari)
        (url:find "^https://squareup.com/") (open-url :safari)
        (url:find "^https://.*[.]bulletin.com/") (open-url :safari)
        (string.find orig-url "^https://doi.org/")
        ((open-with :firefox) (.. "https://sci-hub.st/" orig-url))
        (string.find orig-url "^https://.*[.]usps.com/")
        ((open-with :firefox) orig-url) (open-url :firefox))))

(set hs.urlevent.httpCallback
     (fn [scheme host params url]
       (let [run #(: (io.popen (.. $1 " '" $2 "'")) :read :*a)
             de-utm (partial run "~/.dotfiles/bin/de-utm")
             redirect (partial run "curl -Ls -o /dev/null -w %{url_effective}")
             orig-url (de-utm url)
             redirected (de-utm (redirect orig-url))]
         ;; (hs.urlevent.openURLWithBundle orig-url bundle-ids.firefox))))
         (handle redirected orig-url))))

;;; Elgato Key Light Air

;; finding the hostname for the key light air
; (local browser (: (hs.bonjour.new) :findServices :_elg._tcp.
;                   (fn [browser _ _ service _]
;                     (service:resolve #(log :info (: ($1:hostname) :sub 1 -2)))
;                     (browser:stop))))

(fn update-key-light-air [on?]
  (let [url "http://elgato-key-light-air-5c9e.local:9123/elgato/lights"
        on (if on? 1 0)
        data (hs.json.encode {:lights [{: on}]})]
    (hs.http.doRequest url :PUT data)))

(fn docked? []
  (accumulate [docked? false _ v (pairs (hs.usb.attachedDevices)) &until docked?]
    (or docked? (= v.productName "CalDigit Thunderbolt 3 Audio"))))

(local key-light-air-watcher
       (let [{: watcher} hs.caffeinate]
         (watcher.new #(when (docked?)
                         (match $1
                           watcher.screensDidLock (update-key-light-air false)
                           watcher.screensDidSleep (update-key-light-air false)
                           watcher.screensDidUnlock (update-key-light-air true)
                           watcher.screensDidWake (update-key-light-air true))))))

(when (docked?)
  (key-light-air-watcher:start))

(local usb-watcher (: (hs.usb.watcher.new #(let [{: eventType : productName} $1]
                                             (when (= productName
                                                      "CalDigit Thunderbolt 3 Audio")
                                               (match eventType
                                                 :added (do
                                                          (update-key-light-air true)
                                                          (key-light-air-watcher:start))
                                                 :removed (do
                                                            (update-key-light-air false)
                                                            (key-light-air-watcher:stop))))))
                      :start))

;;; Spoons

(: (hs.loadSpoon :ReloadConfiguration) :start)

; (hs.loadSpoon :Quitter)

; ;; fnlfmt: skip
; (set spoon.Quitter.quitAppsAfter
;      {:Calendar      30
;       :Discord      300
;       :MailMate     600
;       :Messages     300
;       :Reeder       600
;       ; :Slack        300
;       :Telegram     300
;       :Twitterrific 300})

; (spoon.Quitter:start)

(when (hs.fs.attributes :local.fnl)
  (require :local))

(: (hs.notify.new {:title :Hammerspoon
                   :informativeText "Config loaded"
                   :withdrawAfter 2}) :send)


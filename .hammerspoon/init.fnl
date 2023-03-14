(local {: mash : smash : modal-bind} (require :hotkey))

(local {: application
        : caffeinate
        : eventtap
        : execute
        : fs
        : hotkey
        : http
        : json
        : logger
        : loadSpoon
        : notify
        : pasteboard
        : uielement
        : usb} hs)

(local log (logger.new :log :info))
(set logger.defaultLogLevel :info)

(set hs.window.animationDuration 0.0)
(loadSpoon :MiroWindowsManager)
;; (set spoon.MiroWindowsManager.fullScreenSizes [1 (/ 4 3) 2]) ; only fullscreen

;; fnlfmt: skip
(let [{: MiroWindowsManager} spoon]
      (MiroWindowsManager:bindHotkeys {:up         [mash :k]
                                       :left       [mash :h]
                                       :down       [mash :j]
                                       :right      [mash :l]
                                       :fullscreen [mash :m]
                                       ;; :center  [mash  "c"]
                                       ;; :move    [smash "m"]
                                       ;; :resize  [mash  "d"]
                                       }))

;; debugging
;; (hotkey.bind mash "d" (fn [] (hs.dialog.blockAlert "message" "text" "one" "two")))
;; (hotkey.bind mash "d" (fn [] (hs.dialog.alert 100 100 (fn [] ) "message" "text" "one" "two")))

;; defeat paste blocking
(hotkey.bind [:cmd :alt] :v #(eventtap.keyStrokes (pasteboard.getContents)))

(hotkey.bind mash :e
             #(let [app (application.frontmostApplication)
                    prev-pasteboard (pasteboard.getContents)
                    e (uielement.focusedElement)
                    text (if e (e:selectedText)
                             (do
                               (eventtap.keyStroke [:cmd] :c)
                               (pasteboard.getContents)))
                    date (execute "date -Iseconds -u | tr -d '\n'")
                    file (.. "~/.quickcursor." date)]
                (pasteboard.setContents text)
                (execute (.. "pbpaste > " file))
                (execute (.. "/opt/homebrew/bin/neovide --nofork " file))
                (execute (.. "pbcopy < " file))
                (app:setFrontmost)
                (eventtap.keyStroke [:cmd] :v)
                (execute (.. "rm " file))
                (pasteboard.setContents prev-pasteboard)))

(hotkey.bind mash :t #(execute :/opt/homebrew/bin/alacritty))

(fn linkify []
  (let [app (application.frontmostApplication)
        prev-pasteboard (pasteboard.getContents)
        e (uielement.focusedElement)
        text (if e (e:selectedText)
                 (do
                   (eventtap.keyStroke [:cmd] :c)
                   (pasteboard.getContents)))
        link (.. "[" text "]" "(" prev-pasteboard ")")]
    (pasteboard.setContents link)
    (app:setFrontmost)
    (eventtap.keyStroke [:cmd] :v)
    (pasteboard.setContents prev-pasteboard)))

(modal-bind mash "," nil [[mash :l nil linkify]])

;;; Elgato Key Light Air

;; finding the hostname for the key light air
; (local browser (: (hs.bonjour.new) :findServices :_elg._tcp.
;                   (fn [browser _ _ service _]
;                     (service:resolve #(log :info (: ($1:hostname) :sub 1 -2)))
;                     (browser:stop))))

(fn update-key-light-air [on?]
  (let [url "http://elgato-key-light-air-5c9e.local:9123/elgato/lights"
        on (if on? 1 0)
        data (json.encode {:lights [{: on}]})]
    (http.doRequest url :PUT data)))

(fn docked? []
  (accumulate [docked? false _ v (pairs (usb.attachedDevices)) &until docked?]
    (or docked? (= v.productName "CalDigit Thunderbolt 3 Audio"))))

(local key-light-air-watcher (let [{: watcher} caffeinate
                                   w (watcher.new #(when (docked?)
                                                     (match $1
                                                       watcher.screensDidLock (update-key-light-air false)
                                                       watcher.screensDidSleep (update-key-light-air false)
                                                       watcher.screensDidUnlock (update-key-light-air true)
                                                       watcher.screensDidWake (update-key-light-air true))))]
                               (w:start)))

; (local usb-watcher (: (usb.watcher.new #(let [{: eventType : productName} $1]
;                                              (when (= productName
;                                                       "CalDigit Thunderbolt 3 Audio")
;                                                (match eventType
;                                                  :added (do
;                                                           (update-key-light-air true)
;                                                           (key-light-air-watcher:start))
;                                                  :removed (do
;                                                             (update-key-light-air false)
;                                                             (key-light-air-watcher:stop))))))
;                       :start))

;;; Spoons

(: (loadSpoon :ReloadConfiguration) :start)

;; Local overrides
(when (fs.attributes :local.fnl)
  (require :local))

(: (notify.new {:title :Hammerspoon
                :informativeText "Config loaded"
                :withdrawAfter 2}) :send)


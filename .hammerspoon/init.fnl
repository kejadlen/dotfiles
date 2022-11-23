(local {: mash : smash : modal-bind} (require :hotkey))

(local log (hs.logger.new :log :info))
(set hs.logger.defaultLogLevel :info)

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
                   (hs.execute (.. "/opt/homebrew/bin/neovide --nofork " file))
                   (hs.execute (.. "pbcopy < " file))
                   (app:setFrontmost)
                   (hs.eventtap.keyStroke [:cmd] :v)
                   (hs.execute (.. "rm " file))
                   (hs.pasteboard.setContents prev-pasteboard)))

(fn linkify []
  (let [app (hs.application.frontmostApplication)
        prev-pasteboard (hs.pasteboard.getContents)
        e (hs.uielement.focusedElement)
        text (if e (e:selectedText)
                 (do
                   (hs.eventtap.keyStroke [:cmd] :c)
                   (hs.pasteboard.getContents)))
        link (.. "[" text "]" "(" prev-pasteboard ")")]
    (hs.pasteboard.setContents link)
    (app:setFrontmost)
    (hs.eventtap.keyStroke [:cmd] :v)
    (hs.pasteboard.setContents prev-pasteboard)))

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
        data (hs.json.encode {:lights [{: on}]})]
    (hs.http.doRequest url :PUT data)))

(fn docked? []
  (accumulate [docked? false _ v (pairs (hs.usb.attachedDevices)) &until docked?]
    (or docked? (= v.productName "CalDigit Thunderbolt 3 Audio"))))

(local key-light-air-watcher (let [{: watcher} hs.caffeinate
                                   w (watcher.new #(when (docked?)
                                                     (match $1
                                                       watcher.screensDidLock (update-key-light-air false)
                                                       watcher.screensDidSleep (update-key-light-air false)
                                                       watcher.screensDidUnlock (update-key-light-air true)
                                                       watcher.screensDidWake (update-key-light-air true))))]
                               (w:start)))

; (local usb-watcher (: (hs.usb.watcher.new #(let [{: eventType : productName} $1]
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

(: (hs.loadSpoon :ReloadConfiguration) :start)

;; Local overrides
(when (hs.fs.attributes :local.fnl)
  (require :local))

(: (hs.notify.new {:title :Hammerspoon
                   :informativeText "Config loaded"
                   :withdrawAfter 2}) :send)


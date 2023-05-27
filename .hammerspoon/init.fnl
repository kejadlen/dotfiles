;; fennel-ls doesn't support arbitrary allowed globals, so
;; unwrap `hs` here to localize it to just one place
(local {: application
        : dialog
        : eventtap
        : execute
        : fs
        : hotkey
        : ipc
        : loadSpoon
        : logger
        : notify
        : pasteboard
        : uielement
        : window} hs)

(local log (logger.new :log :info))
(set logger.defaultLogLevel :info)

(local {: mash : smash : modal-bind} (require :hotkey))

;; debugging
; (hotkey.bind mash "d" #(dialog.blockAlert "message" "text" "one" "two"))

;; defeat paste blocking
(hotkey.bind [:cmd :alt] :v #(eventtap.keyStrokes (pasteboard.getContents)))

(fn run [...]
  (accumulate [last nil _ cmd (ipairs [...])]
    (execute cmd)))

(fn with-selection [cb]
  (let [app (application.frontmostApplication)
        prev-pasteboard (pasteboard.getContents)
        e (uielement.focusedElement)
        text (if e (e:selectedText)
                 (do
                   (eventtap.keyStroke [:cmd] :c)
                   (pasteboard.getContents)))
        content (cb text prev-pasteboard)]
    (pasteboard.setContents content)
    (app:setFrontmost)
    (eventtap.keyStroke [:cmd] :v)
    (pasteboard.setContents prev-pasteboard)))

(fn chomp [s]
  (if (= (s:sub -1) "\n")
      (s:sub 1 -2)
      s))

(hotkey.bind mash :e
             #(with-selection (fn [text]
                                (let [home (os.getenv :HOME)
                                      date (chomp (run "date -Iseconds -u"))
                                      file (.. home :/.quickcursor. date)]
                                  (pasteboard.setContents text)
                                  (run (.. "pbpaste > " file)
                                       (.. "/opt/homebrew/bin/neovide --nofork "
                                           file)
                                       (.. "pbcopy < " file) (.. "rm " file))
                                  (pasteboard.getContents)))))

(hotkey.bind mash :t #(execute "/opt/homebrew/bin/alacritty msg create-window"))

(modal-bind mash "," nil
            [[mash
              :l
              nil
              (fn []
                (with-selection #(.. "[" $1 "]" "(" $2 ")")))]])

;;; Elgato Key Light Air

;; Run `package.loaded["key-light-air"]["find-hostname"]()`
;; to find the hostname of the Key Light Air
(require :key-light-air)

;;; Spoons

(loadSpoon :SpoonInstall)
(local {:SpoonInstall Install} spoon)
(set Install.use_syncinstall true)

;; fnlfmt: skip
(local hotkeys {:up         [mash :k]
                :left       [mash :h]
                :down       [mash :j]
                :right      [mash :l]
                :fullscreen [mash :m]
                :nextscreen [mash :n]})

(set window.animationDuration 0.0)
(Install:andUse :MiroWindowsManager {:config {:GRID {:w 6 :h 4}} : hotkeys})

(Install:andUse :WindowGrid {:config {:gridGeometries [[:6x4]]}
                             :hotkeys {:show_grid [mash :g]}
                             :start true})

(let [browsers {:arc :company.thebrowser.Browser
                :firefox-dev :org.mozilla.firefoxdeveloperedition
                :firefox :org.mozilla.firefox
                :safari :com.apple.Safari
                :zoom :us.zoom.xos}
      url_patterns [["^https://(.*%.?)zoom.us/j/%d+" browsers.zoom]
                    ["^https://(.*%.?)discnw.org/?" browsers.safari]
                    ["^https://(.*%.?)squareupmessaging.com/?" browsers.safari]
                    ["^https://(.*%.?)bulletin.com/?" browsers.safari]
                    ["^https://(.*%.?)store.apple.com/?" browsers.safari]
                    ["^https://(.*%.?)goodluckbread.com/?" browsers.safari]
                    ["^https://community.glowforge.com/?" browsers.arc]]
      url_redir_decoders [[:sci-hub
                           "^https://doi.org/(.*)"
                           "https://sci-hub.st/%1"]]]
  (Install:andUse :URLDispatcher {:config {: url_patterns
                                           : url_redir_decoders
                                           :default_handler browsers.firefox-dev}
                                  :start true}))

(Install:andUse :ReloadConfiguration {:start true})

;; Local overrides
(when (fs.attributes :local.fnl)
  (require :local))

(let [n (notify.new {:title :Hammerspoon
                     :informativeText "Config loaded"
                     :withdrawAfter 2})]
  (n:send))


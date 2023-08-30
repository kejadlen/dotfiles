;; fennel-ls doesn't support arbitrary allowed globals, so
;; unwrap `hs` here to localize it to just one place
(local {: application
        : canvas
        : dialog
        : eventtap
        : execute
        : fs
        : hotkey
        : ipc
        : inspect
        : loadSpoon
        : logger
        : notify
        : pasteboard
        : screen
        : uielement
        : urlevent
        : window} hs)

(local log (logger.new :init :info))
; (set logger.defaultLogLevel :info)

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

(set window.animationDuration 0.0)

;; fnlfmt: skip
(let [hotkeys {:up         [mash :k]
               :left       [mash :h]
               :down       [mash :j]
               :right      [mash :l]
               :fullscreen [mash :m]
               :nextscreen [mash :n]}]
  (Install:andUse :MiroWindowsManager {: hotkeys}))

(Install:andUse :SleepCorners {:config {:feedbackSize 100} :start true})

;; By default, URLDispatcher focuses the application before opening the URL, but
;; this interacts poorly with Arc since then we can be in the wrong space when
;; the URL is opened in Little Arc.
(let [handlers {:arc #(urlevent.openURLWithBundle $1
                                                  :company.thebrowser.Browser)
                :firefox-dev :org.mozilla.firefoxdeveloperedition
                :firefox :org.mozilla.firefox
                :safari :com.apple.Safari
                :zoom :us.zoom.xos}
      url_patterns [["^https://(.*%.?)zoom.us/j/%d+" handlers.zoom]
                    ["^https://(.*%.?)discnw.org/?" handlers.safari]
                    ["^https://(.*%.?)squareupmessaging.com/?" handlers.safari]
                    ["^https://(.*%.?)bulletin.com/?" handlers.safari]
                    ["^https://(.*%.?)store.apple.com/?" handlers.safari]
                    ["^https://(.*%.?)goodluckbread.com/?" handlers.safari]
                    ["^https://community.glowforge.com/?" handlers.arc]
                    ["^https://accounts.google.com/?" handlers.arc]]
      url_redir_decoders [[:sci-hub
                           "^https://doi.org/(.*)"
                           "https://sci-hub.st/%1"]
                          [:twitter
                           "^https://twitter.com/(.*)"
                           "https://nitter.net/%1"]]]
  (Install:andUse :URLDispatcher {:config {: url_patterns
                                           : url_redir_decoders
                                           :default_handler handlers.arc
                                           :set_system_handler true}
                                  :start true}))

(Install:andUse :ReloadConfiguration {:start true})

;; Local overrides
(when (fs.attributes :local.fnl)
  (require :local))

(let [n (notify.new {:title :Hammerspoon
                     :informativeText "Config loaded"
                     :withdrawAfter 2})]
  (n:send))


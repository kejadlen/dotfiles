;; fennel-ls doesn't support arbitrary allowed globals, so
;; unwrap `hs` here to localize it to just one place
(local {: application
        : dialog
        : eventtap
        : execute
        : fs
        : hotkey
        :loadSpoon load_spoon
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

(hotkey.bind mash :t #(execute :/opt/homebrew/bin/alacritty))

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

;;; Quitter

(let [{: start} (require :quitter-fnl)]
  (start {:Calendar 30
          :Discord 300
          :MailMate 600
          :Messages 300
          :Reeder 600
          :Slack 300
          :Telegram 300}))

;;; Spoons

(load_spoon :SpoonInstall)
(local {:SpoonInstall Install} spoon)
(set Install.use_syncinstall true)

;; fnlfmt: skip
(let [hotkeys {:up         [mash :k]
               :left       [mash :h]
               :down       [mash :j]
               :right      [mash :l]
               :fullscreen [mash :m]
               :nextscreen [mash :n]}]
  (set window.animationDuration 0.0)
  (Install:andUse :MiroWindowsManager {: hotkeys}))

(Install:andUse :ReloadConfiguration)

;; Local overrides
(when (fs.attributes :local.fnl)
  (require :local))

(: (notify.new {:title :Hammerspoon
                :informativeText "Config loaded"
                :withdrawAfter 2}) :send)


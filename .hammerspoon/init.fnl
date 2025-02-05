;; fennel-ls doesn't support arbitrary allowed globals, so
;; unwrap `hs` here to localize it to just one place
(local {: eventtap
        : fs
        : hotkey
        : loadSpoon
        : logger
        : notify
        : pasteboard
        : urlevent
        : window} hs)

(local log (logger.new :init :info))
; (set logger.defaultLogLevel :info)

(local {: mash : smash : modal-bind} (require :hotkey))
(local {: chomp : paste : replace-selection : run} (require :utils))

;; debugging
; (hotkey.bind mash "d" #(hs.notify.show (: (hs.window.frontmostWindow) :title) "" ""))

;; ⌘⌥V - defeat paste blocking
(hotkey.bind [:cmd :alt] :v #(eventtap.keyStrokes (pasteboard.getContents)))

;; ⌘⌥⌃E - edit selected text in neovide, inspired by quickcursor (hence the temporary filenme)
(let [editor "/opt/homebrew/bin/neovide --no-fork"
      cb (fn [text]
           (let [home (os.getenv :HOME)
                 date (chomp (run "date -Iseconds -u"))
                 file (.. home :/.quickcursor. date)]
             (pasteboard.setContents text)
             (run (.. "pbpaste > " file) (.. editor " " file)
                  (.. "pbcopy < " file) (.. "rm " file))
             (pasteboard.getContents)))]
  (hotkey.bind mash :e #(replace-selection cb)))

;; mash-, modal hotkeys
(modal-bind mash "," nil
            ;; mash-, mash-l: create a markdown link using the selected
            ;; text as the title and pastboard contents as the link
            [[mash
              :l
              nil
              (fn []
                (replace-selection #(.. "[" $1 "]" "(" $2 ")")))]])

;;; quitter

(let [quitter (require :quitter)]
  (quitter:start))

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

(Install:andUse :SleepCorners {:config {:feedbackSize 25 :neverSleepCorner "*"}
                               :start true})

;; By default, URLDispatcher focuses the application before opening the URL, but
;; this interacts poorly with Arc since then we can be in the wrong space when
;; the URL is opened in Little Arc.
(let [open-in-arc #(urlevent.openURLWithBundle $1 :company.thebrowser.Browser)
      handlers {:arc open-in-arc
                :firefox-dev :org.mozilla.firefoxdeveloperedition
                :firefox :org.mozilla.firefox
                :safari :com.apple.Safari
                :zoom :us.zoom.xos}
      url-patterns [["^https://(.*%.?)zoom.us/j/%d+" handlers.zoom]
                    ["^https://(.*%.?)discnw.org/?" handlers.safari]
                    ["^https://(.*%.?)squareupmessaging.com/?" handlers.safari]
                    ["^https://(.*%.?)bulletin.com/?" handlers.safari]
                    ["^https://(.*%.?)store.apple.com/?" handlers.safari]
                    ["^https://(.*%.?)goodluckbread.com/?" handlers.safari]
                    ["^https://community.glowforge.com/?" handlers.arc]
                    ["^https://accounts.google.com/?" handlers.arc]
                    ["^https://(.*%.?)fidelityinvestments.com/?"
                     handlers.safari]
                    ["^https://mychartwa.providence.org/?"
                     handlers.firefox-dev]
                    ["^https://www.bankofamerica.com/?" handlers.safari]]
      url-redir-decoders [[:sci-hub
                           "^https://doi.org/(.*)"
                           "https://sci-hub.st/%1"]]]
  (Install:andUse :URLDispatcher {:config {:url_patterns url-patterns
                                           :url_redir_decoders url-redir-decoders
                                           :default_handler handlers.arc
                                           :set_system_handler true}
                                  :start true}))

(Install:andUse :ReloadConfiguration {:start true})

;; Local overrides
(when (fs.attributes :local.fnl)
  (require :local))

(: (notify.new {:title :Hammerspoon
                :informativeText "Config loaded"
                :withdrawAfter 2}) :send)


;; fennel-ls doesn't support arbitrary allowed globals, so
;; unwrap `hs` here to localize it to just one place
(local {: eventtap
        : execute
        :fnutils {: map}
        : fs
        : hotkey
        : loadSpoon
        : logger
        : notify
        : pasteboard
        : pathwatcher
        : screen
        : urlevent
        : window} hs)

(local log (logger.new :init :info))
; (set logger.defaultLogLevel :info)

(local {: mash : smash : modal-bind} (require :hotkey))
(local {: chomp : debounce : paste : replace-selection : run} (require :utils))
(local little-ff (require :little-ff))

;; debugging
; (hotkey.bind mash :d #(little-ff.open "https://google.com"))

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

;;; reload sketchybar on screen changes

(set _G.screen-watcher
     (screen.watcher.new (debounce 1.0
                                   (fn []
                                     (log:i "Screen configuration changed, reloading sketchybar")
                                     (execute "/opt/homebrew/bin/sketchybar --reload")))))

(_G.screen-watcher:start)

;;; reload aerospace on config changes

(let [home (os.getenv :HOME)
      aerospace-config (.. home :/.config/aerospace/aerospace.toml)]
  (set _G.aerospace-watcher
       (pathwatcher.new aerospace-config
                        (fn []
                          (execute "/opt/homebrew/bin/aerospace reload-config")
                          (let [n (notify.new {:title :Aerospace
                                               :informativeText "Config reloaded"
                                               :withdrawAfter 2})]
                            (n:send)))))
  (_G.aerospace-watcher:start))

;;; wm

(let [{: init : step} (require :wm)]
  (init)
  (hotkey.bind mash :m step))

;;; Spoons

(loadSpoon :SpoonInstall)
(local {:SpoonInstall Install} spoon)
(set Install.use_syncinstall true)

(set window.animationDuration 0.0)

(Install:andUse :SleepCorners {:config {:feedbackSize 25 :neverSleepCorner "*"}
                               :start true})

(fn sanitize-url [url]
  ;; Skip AWS SSO URLs — trurl encodes slashes in hash-routed fragments.
  (if (string.match url "%.awsapps%.com/start/#/")
      url
      (let [tracking-params [:utm_* :uta_* :fbclid :gclid]
            trurl-cmd (.. :/opt/homebrew/bin/trurl " "
                          (table.concat (map tracking-params #(.. "--qtrim " $1))
                                        " "))]
        (chomp (execute (.. trurl-cmd " --url \"" url "\""))))))

(let [handlers {:firefox-dev :org.mozilla.firefoxdeveloperedition
                :firefox :org.mozilla.firefox
                :glide :app.glide-browser.glide
                :safari :com.apple.Safari
                :zoom :us.zoom.xos}
      ;; domains to be opened in Safari, most for Apple Pay
      safari-domains [:apps.apple.com
                      :account.apple.com
                      :goodluckbread.com
                      :patagonia.com
                      :squareupmessagine.com
                      :store.apple.com]
      safari-patterns (icollect [_ domain (ipairs safari-domains)]
                        (.. "^https://(.*%.?)" (string.gsub domain "%." "%%.")
                            "/?"))
      url-patterns [["^https://(.*%.?)zoom.us/j/%d+" handlers.zoom]
                    [safari-patterns handlers.safari]]
      url-redir-decoders [[:trurl-sanitize #(sanitize-url $4) nil true]
                          [:reddit "://www%.reddit%.com" "://old.reddit.com"]
                          [:xcancel "://x%.com" "://xcancel.com"]]]
  (Install:andUse :URLDispatcher {:config {:url_patterns url-patterns
                                           :url_redir_decoders url-redir-decoders
                                           :default_handler little-ff.open
                                           :set_system_handler true}
                                  :start true}))

; Reopen what's in Little Firefox in the main window
(hotkey.bind mash :o little-ff.rehome)

(Install:andUse :ReloadConfiguration {:start true})

;; Local overrides
(when (fs.attributes :local.fnl)
  (require :local))

(let [n (notify.new {:title :Hammerspoon
                     :informativeText "Config loaded"
                     :withdrawAfter 2})]
  (n:send))

;; hold onto globals so they don't get GC'ed?
{}

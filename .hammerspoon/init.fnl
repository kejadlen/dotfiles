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
    (if (string.find url "^https://.*[.]zoom.us/j/%d+") (open-url :zoom)
        (string.find url "^https://.*[.]discnw.org/") (open-url :safari)
        (string.find url "^https://squareup.com/") (open-url :safari)
        (string.find orig-url "^https://doi.org/")
        ((open-with :firefox) (.. "https://sci-hub.st/" orig-url))
        (open-url :firefox))))

(set hs.urlevent.httpCallback
     (fn [scheme host params url]
       (let [run #(: (io.popen (.. $1 " \"" $2 "\"")) :read :*a)
             de-utm (partial run "~/.dotfiles/bin/de-utm")
             redirect (partial run "curl -Ls -o /dev/null -w %{url_effective}")
             orig-url (de-utm url)
             redirected (de-utm (redirect orig-url))]
         (handle redirected orig-url))))

;;; Spoons

(: (hs.loadSpoon :ReloadConfiguration) :start)

(hs.loadSpoon :Quitter)

;; fnlfmt: skip
(set spoon.Quitter.quitAppsAfter
     {:Discord      300
      :MailMate     600
      :Messages     300
      :Reeder       600
      :Slack        300
      :Telegram     300
      :Twitterrific 300})

(spoon.Quitter:start)

(: (hs.notify.new {:title :Hammerspoon
                   :informativeText "Config loaded"
                   :withdrawAfter 2}) :send)


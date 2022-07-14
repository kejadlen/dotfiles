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
(local matchers {".*[.]zoom.us/j/%d+" :us.zoom.xos
                 ".*[.]webex.com/"    :com.webex.meetingmanager
                 ".*[.]discnw.org/"   :com.apple.Safari
                 :squareup.com/       :com.apple.Safari})

(fn bundleIDForURL [url]
  (var bundleID nil)
  (each [key value (pairs matchers) :until bundleID]
    (if (string.find url (.. "^https://" key))
        (set bundleID value)))
  (or bundleID :org.mozilla.firefoxdeveloperedition))

(set hs.urlevent.httpCallback
     (fn [scheme host params url]
       (let [run #(: (io.popen (.. $1 " \"" $2 "\"")) :read :*a)
             de-utm (partial run "~/.dotfiles/bin/de-utm")
             redirect (partial run "curl -Ls -o /dev/null -w %{url_effective}")
             final-url (->> url
                            (de-utm)
                            (redirect)
                            (de-utm))
             bundleID (bundleIDForURL final-url)]
         (hs.urlevent.openURLWithBundle final-url bundleID))))

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

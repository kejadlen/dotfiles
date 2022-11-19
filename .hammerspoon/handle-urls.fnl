;; https://stackoverflow.com/questions/39464668/how-to-get-bundle-id-of-mac-application
;;   osascript -e 'id of app "SomeApp"'
;;   mdls -name kMDItemCFBundleIdentifier -r SomeApp.app
;; (. (hs.application.infoForBundlePath "/path/to/app") :CFBundleIdentifier)

(local bundle-ids {:firefox-dev :org.mozilla.firefoxdeveloperedition
                   :firefox :org.mozilla.firefox
                   :safari :com.apple.Safari
                   :zoom :us.zoom.xos})

(var handlers [])

(fn run [bin url]
  (let [prog (.. bin " '" url "'")
        handle (io.popen prog)]
    (handle:read :*a)))

(fn de-utm [url]
  (run "~/.dotfiles/bin/de-utm" url))

(fn follow-redirects [url]
  (run "curl --location --silent -o /dev/null -w %{url_effective}" url))

(fn open-url [app url]
  (let [bundle-id (. bundle-ids app)]
    (hs.urlevent.openURLWithBundle url bundle-id)))

(fn open-with [app]
  (partial open-url app))

(local default-handlers
       [["^https://.*%.?zoom.us/j/%d+" (open-with :zoom)]
        ["^https://doi.org/"
         #(open-with :default (.. "https://sci-hub.st/" $1))]])

(fn url->handler [url]
  (accumulate [acc nil _ [pat handler] (ipairs handlers) &until acc]
    (if (url:find pat) #(handler url) nil)))

(fn handle-url [url]
  (let [handler (or (url->handler url) #(open-url :default url))]
    (handler)))

(fn setup [{:bundle-ids extra-bundle-ids :handlers extra-handlers}]
  (each [k v (pairs (or extra-bundle-ids {}))]
    (tset bundle-ids k v))
  (set handlers (hs.fnutils.concat extra-handlers default-handlers)))

(fn start []
  (set hs.urlevent.httpCallback
       (fn [scheme host params url]
         (let [clean-url (de-utm url)]
           (handle-url clean-url)))))

;; example usage
;;
;; (let [{: setup : start : open-with} (require :handle-urls)]
;;   (setup {:bundle-ids {:default :org.mozilla.firefoxdeveloperedition}
;;           :handlers [["^https://.*%.?discnw.org/" (open-with :safari)]
;;                      ["^https://squareup.com/" (open-with :safari)]
;;                      ["^https://.*%.?bulletin.com/" (open-with :safari)]]})
;;   (start))

{: setup : start : open-url : open-with}


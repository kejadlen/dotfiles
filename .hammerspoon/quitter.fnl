(local {: application
        : caffeinate
        :fnutils {: contains : ifilter}
        : logger
        : notify
        : timer
        : window} hs)

(local log (logger.new :quitter :debug))

(local config {:permanent-apps [:Arq
                                "Firefox Developer Edition"
                                :Ghostty
                                :Miniflux
                                :Phanpy
                                :Obsidian
                                "Raspberry Pi Imager"
                                :Safari]
               :app-overrides {:Music [:hour 1]
                               :Raindrop [:minute 15]
                               "UniFi Protect" [:minute 30]
                               :zoom.us [:hour 1]}
               :default-timeout [:minute 5]})

(fn kill-delay [app-name]
  (let [[interval count] (or (?. config.app-overrides app-name)
                             config.default-timeout)
        seconds (. {:minute 60 :hour (* 60 60)} interval)]
    (* count seconds)))

(local to-kill {})

(fn kill [app]
  ;; in theory if the app is frontmost it shouldn't
  ;; be marked, but an extra precaution since we never
  ;; want to kill the focused app
  (when (not (app:isFrontmost))
    (let [app-name (app:name)
          focused-win (window.focusedWindow)
          msg (.. "Killing " app-name)
          n (notify.new {:title :Quitter :informativeText msg :withdrawAfter 2})]
      (log.i msg)
      (n:send)
      (app:kill)
      (focused-win:focus))))

(fn unmark [app]
  (let [bundle-id (app:bundleID)
        t (?. to-kill bundle-id)]
    (when (not= t nil)
      (log.i (.. "unmarking " (app:name)))
      (t:stop)
      (set (. to-kill bundle-id) nil))))

(fn mark [app]
  (when (and (not (contains config.permanent-apps (app:name))) (= (app:kind) 1))
    (unmark app)
    (let [delay (kill-delay (app:name))]
      (log.i (.. "marking " (app:name) " to be killed after " delay))
      (set (. to-kill (app:bundleID)) (timer.doAfter delay #(kill app))))))

(fn mark-all-apps []
  (log.d :mark-all-apps)
  (each [_ app (ipairs (ifilter [(application.find "")]
                                #(not (contains config.permanent-apps ($1:name)))))]
    (mark app)))

(local cw (caffeinate.watcher.new #(when (= $1 caffeinate.watcher.systemDidWake)
                                     (mark-all-apps))))

(local wf (let [filter-config {:default true}]
            (each [_ app-name (ipairs config.permanent-apps)]
              (tset filter-config app-name false))
            (window.filter.new filter-config)))

(fn start []
  (log.i :starting)
  (mark-all-apps)
  (cw:start)
  (wf:subscribe {window.filter.windowFocused #(unmark ($1:application))
                 window.filter.windowUnfocused #(mark ($1:application))}))

;; use global so this isn't GC'ed?
(set _G.quitter {: cw : to-kill : wf})

{: start}

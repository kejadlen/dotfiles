(local {: application : caffeinate : logger : timer : window} hs)

(local log (logger.new :quitter :info))

(local to-kill {})

(fn kill [app]
  (when (not (app:isFrontmost))
    (log.i (.. "killing " (app:name)))
    (app:kill)))

(fn mark [app]
  (when (= (app:kind) 1)
    (log.i (.. "marking " (app:name)))
    (set (. to-kill (app:bundleID)) (timer.doAfter 300 #(kill app)))))

(fn unmark [win]
  (let [app (win:application)
        bundle-id (app:bundleID)
        t (?. to-kill bundle-id)]
    (when (not= t nil)
      (log.i (.. "unmarking " (app:name)))
      (t:stop)
      (set (. to-kill bundle-id) nil))))

(fn mark-all-apps [event]
  (when (= event caffeinate.watcher.systemDidWake)
    (each [_ app (ipairs (application.find ""))]
      (mark app))))

(local cw (caffeinate.watcher.new mark-all-apps))

(local wf (window.filter.new {:Safari false
                              :Arc false
                              "Firefox Developer Edition" false
                              :Ghostty false
                              :Miniflux false
                              :Phanpy false
                              :Obsidian false
                              :default true}))

(fn start []
  (log.i :starting)
  (mark-all-apps)
  (cw:start)
  (wf:subscribe {window.filter.windowFocused unmark
                 window.filter.windowUnfocused #(mark ($1:application))}))

;; use global so this isn't GC'ed
(set _G.quitter {: to-kill})

{: start}

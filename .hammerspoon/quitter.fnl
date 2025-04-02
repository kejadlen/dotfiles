(local {: application
        : caffeinate
        : fnutils
        : logger
        : notify
        : timer
        : window} hs)

(local {: contains : ifilter} fnutils)

(local log (logger.new :quitter :debug))

(local keep-apps [:Safari
                  :Arc
                  "Firefox Developer Edition"
                  :Ghostty
                  :LibreWolf
                  :Miniflux
                  :Phanpy
                  :Obsidian])

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
  (when (= (app:kind) 1)
    (unmark app)
    (log.i (.. "marking " (app:name)))
    (set (. to-kill (app:bundleID)) (timer.doAfter 300 #(kill app)))))

(fn mark-all-apps []
  (log.d :mark-all-apps)
  (each [_ app (ipairs (ifilter [(application.find "")]
                                #(not (contains keep-apps ($1:name)))))]
    (mark app)))

(local cw (caffeinate.watcher.new #(when (= $1 caffeinate.watcher.systemDidWake)
                                     (mark-all-apps))))

(local wf (window.filter.new {:Safari false
                              :Arc false
                              "Firefox Developer Edition" false
                              :Ghostty false
                              :LibreWolf false
                              :Miniflux false
                              :Phanpy false
                              :Obsidian false
                              :default true}))

(fn start []
  (log.i :starting)
  (mark-all-apps)
  (cw:start)
  (wf:subscribe {window.filter.windowFocused #(unmark ($1:application))
                 window.filter.windowUnfocused #(mark ($1:application))}))

;; use global so this isn't GC'ed
(set _G.quitter {: cw : to-kill : wf})

{: start}

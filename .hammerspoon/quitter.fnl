(local {: application : caffeinate : fnutils : logger : timer : window} hs)

(local {: contains : ifilter} fnutils)

(local log (logger.new :quitter :debug))

(local keep-apps [:Safari
                  :Arc
                  "Firefox Developer Edition"
                  :Ghostty
                  :Miniflux
                  :Phanpy
                  :Obsidian])

(local to-kill {})

(fn kill [app]
  (when (not (app:isFrontmost))
    (log.i (.. "killing " (app:name)))
    (let [focused-win (window.focusedWindow)]
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
(set _G.quitter {: to-kill})

{: start}

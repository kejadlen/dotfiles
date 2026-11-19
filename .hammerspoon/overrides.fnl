;; An untracked local.fnl may return a table of per-machine settings:
;;
;;   {:url-patterns [[pattern bundle-id] ...]  ; checked before the shared ones
;;    :quitter {:keep [app-name ...] :timeouts {app-name [unit count]}}}
;;
;; One that returns nothing still runs for its side effects.
(let [m (when (hs.fs.attributes :local.fnl) (require :local))]
  (if (= :table (type m)) m {}))

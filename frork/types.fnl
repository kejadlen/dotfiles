(local {: register :utils {: chomp : expand-path : sh : sh!}} (require :frork))

;; Stand-in until frork implements `no`, which would cover this directly.
;; Inverted: :missing means something is still at the path, so install deletes it.
(register :absent
          (let [resolve #(let [path (expand-path $1)
                               home (expand-path :$HOME)]
                           (when (or (= path "") (= path "/") (= path home)
                                     (= path (.. home "/")))
                             (error (.. "refusing to remove " path)))
                           path)]
            {:status #(let [(_ rc) (sh :sh :-c "test -e \"$1\" || test -L \"$1\""
                                       :sh (resolve $1))]
                        (if (= rc 0) :missing :ok))
             :install #(sh! :rm :-rf (resolve $1))}))

(register :defaults (let [defaults #(let [(output rc) (sh :defaults $...)]
                                      (values (chomp output) rc))]
                      {:status (fn [domain key typ val]
                                 ;; (assert-bin :defaults)
                                 (if (or (= typ :dictionary) (= typ :array))
                                     ;; I don't need this (yet), so defer implementation
                                     (error :todo))
                                 (let [normalize-value (fn [typ val]
                                                         (case [typ val]
                                                           [:boolean :1] :true
                                                           [:boolean :0] :false
                                                           _ (val:gsub "\\\\"
                                                                       "\\")))
                                       normalize-type #(or (. {:bool :boolean
                                                               :int :integer}
                                                              $1)
                                                           $1)
                                       (current-value rc) (defaults :read
                                                            domain
                                                            key)
                                       ;; extract the type from the "Type is {type}" output
                                       current-type (accumulate [t nil m (: (defaults :read-type
                                                                              domain
                                                                              key)
                                                                            :gmatch
                                                                            "%S+")]
                                                      m)]
                                   (if (not= rc 0)
                                       :missing
                                       (or (not= current-type
                                                 (normalize-type typ))
                                           (not= (normalize-value current-type
                                                                  current-value)
                                                 (tostring val)))
                                       (values :conflict-upgrade
                                               {:expected (tostring val)
                                                :actual (normalize-value current-type
                                                                         current-value)})
                                       :ok)))
                       :install #(defaults :write $1 $2 (.. "-" $3) (tostring $4))
                       :upgrade #(defaults :write $1 $2 (.. "-" $3) (tostring $4))
                       :remove #(defaults :delete $1 $2)}))

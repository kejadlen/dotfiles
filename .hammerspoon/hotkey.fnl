(local mash [:cmd :alt :ctrl])
(local smash [:shift :cmd :alt :ctrl])

(fn modal-bind [mods key message bindings]
  (let [modal (hs.hotkey.modal.new mods key message)]
    (tset modal :entered #(hs.timer.doAfter 1 #(modal:exit)))
    ;; (tset modal :exited #(hs.alert :bye))
    (each [_ [mods key message f] (ipairs bindings)]
      (modal:bind mods key message
                  #(do
                     (f)
                     (modal:exit))))))

{: mash : smash : modal-bind}


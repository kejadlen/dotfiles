(fn modal-bind [mods key message bindings]
  (let [modal (hs.hotkey.modal.new mods key message)]
    (tset modal :entered #(hs.timer.doAfter 0.5 #(modal:exit)))
    ; (tset modal :exited #(hs.alert :exited))
    (each [_ [mods key message f] (ipairs bindings)]
      (modal:bind mods key message #(do (f) (modal:exit))))))

{:mash [:cmd :alt :ctrl] :smash [:cmd :alt :ctrl :shift] : modal-bind}


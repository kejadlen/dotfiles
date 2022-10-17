;; https://github.com/rktjmp/hotpot.nvim/blob/master/COOKBOOK.md#using-hotpot-reflect

;; Open session and attach input in one step.
;; Note the complexity here is mostly due to nvim not having an api to create a
;; split window, so we must shuffle some code to create a buf, pair input and output
;; then put that buf inside a window.
; (local reflect-session {:id nil :mode :compile})
; (fn new-or-attach-reflect []
;   (let [{: api} vim
;         reflect (require :hotpot.api.reflect)
;         with-session-id (if reflect-session.id
;                           (fn [f]
;                             ;; session id already exists, so we can just pass
;                             ;; it to whatever needs it
;                             (f reflect-session.id))
;                           (fn [f]
;                             ;; session id does not exist, so we need to create
;                             ;; an output buffer first then we can pass the
;                             ;; session id on, and finally hook up the output
;                             ;; buffer to a window
;                             (let [buf (api.nvim_create_buf true true)
;                                   id (reflect.attach-output buf)]
;                               (set reflect-session.id id)
;                               (f id)
;                               ;; create window, which will forcibly assume focus, swap the buffer
;                               ;; to our output buffer and setup an autocommand to drop the session id
;                               ;; when the session window is closed.
;                               (vim.schedule #(do
;                                                (api.nvim_command "botright vnew")
;                                                (api.nvim_win_set_buf (api.nvim_get_current_win) buf)
;                                                (api.nvim_create_autocmd :BufWipeout
;                                                                         {:buffer buf
;                                                                          :once true
;                                                                          :callback #(set reflect-session.id nil)}))))))]
;     ;; we want to set the session mode to our current mode, and attach the
;     ;; input buffer once we have a session id
;     (with-session-id (fn [session-id]
;                        ;; we manually set the mode each time so it is persisted if we close the session.
;                        ;; By default `reflect` will use compile mode.
;                        (reflect.set-mode session-id reflect-session.mode)
;                        (reflect.attach-input session-id 0)))))
; (vim.keymap.set :v :hr new-or-attach-reflect)

; (fn swap-reflect-mode []
;   (let [reflect (require :hotpot.api.reflect)]
;     ;; only makes sense to do this when we have a session active
;     (when reflect-session.id
;       ;; swap held mode
;       (if (= reflect-session.mode :compile)
;         (set reflect-session.mode :eval)
;         (set reflect-session.mode :compile))
;       ;; tell session to use new mode
;       (reflect.set-mode reflect-session.id reflect-session.mode))))
; (vim.keymap.set :n :hx swap-reflect-mode)

;; https://github.com/rktjmp/hotpot.nvim/blob/master/COOKBOOK.md#using-the-api

(fn pecho [ok? ...]
  "nvim_echo vargs, as DiagnosticHint or DiagnosticError depending on ok?"
  (let [{: nvim_echo} vim.api
        {: view} (require :hotpot.fennel)
        hl (if ok? :DiagnosticHint :DiagnosticError)
        list [...]
        output (fcollect [i 1 (select "#" ...)]
                         (-> (. list i)
                             (#(match (type $1)
                                 :table (view $1)
                                 _ (tostring $1)))
                             (.. "\n")))]
    (nvim_echo (icollect [_ l (ipairs output)]
                 [l hl]) true {})))

(vim.keymap.set :n :heb #(let [{: eval-buffer} (require :hotpot.api.eval)]
                           (pecho (eval-buffer 0)))
                {:desc "Evaluate entire buffer"})

(vim.keymap.set :v :hes #(let [{: eval-selection} (require :hotpot.api.eval)]
                           (pecho (eval-selection)))
                {:desc "Evaluate selection"})

(vim.keymap.set :n :hcb #(let [{: compile-buffer} (require :hotpot.api.compile)]
                           (pecho (compile-buffer 0)))
                {:desc "Compile entire buffer"})

(vim.keymap.set :v :hcs #(let [{: compile-selection} (require :hotpot.api.compile)]
                           (pecho (compile-selection)))
                {:desc "Compile selection"})


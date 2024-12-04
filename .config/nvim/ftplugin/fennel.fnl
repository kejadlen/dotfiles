;; https://github.com/rktjmp/hotpot.nvim/discussions/93#discussioncomment-4362209
(vim.cmd "iabbrev <buffer> <expr> lambda v:lua.iab_lambda()")

;; fnlfmt: skip
(fn _G.iab_lambda []
  (let [line (vim.fn.getline :.)
        col (vim.fn.col :.)
        ;; a b c \lambda
        ;;       ^ check here (may not exist)
        ;; but dont do anything if that under runs the first character
        offset (- col (length :lambda) 1)]
    (match [(< 0 offset) (string.sub line offset offset)]
      ;; replace term codes so the expr actually runs backspace, not inserts the string
      [true :\] (vim.api.nvim_replace_termcodes :<bs>λ true false true)
      [false _] :lambda)))

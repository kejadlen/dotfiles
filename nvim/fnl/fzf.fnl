;; https://github.com/junegunn/fzf/blob/master/README-VIM.md

(fn init-keymaps []
  (vim.keymap.set :n :<leader>b ":Buffers<cr>" {:noremap true})
  (vim.keymap.set :n :<leader>f ":Files<cr>" {:noremap true})
  (vim.keymap.set :n :<leader>t ":Tags<cr>" {:noremap true}))

;; https://coreyja.com/vim-spelling-suggestions-fzf/
(fn init-fzf-spell []
  (let [{: nvim_command : nvim_create_user_command} vim.api
        {: expand "fzf#run" fzf-run "fzf#wrap" fzf-wrap : spellsuggest} vim.fn
        sink #(nvim_command (.. "normal! \"_ciw" $1))
        fzf-spell #(fzf-run (fzf-wrap {:source (spellsuggest (expand :<cword>))
                                       : sink
                                       :window {:width 0.9 :height 0.6}}))]
    (vim.api.nvim_create_user_command :FzfSpell fzf-spell {})
    (vim.keymap.set :n :z= ":FzfSpell<cr>" {:noremap true})))

(when (vim.fn.isdirectory :/opt/homebrew/opt/fzf/plugin)
  (vim.opt.rtp:append :/opt/homebrew/opt/fzf)
  (init-keymaps)
  (init-fzf-spell))


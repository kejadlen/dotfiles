(set vim.g.omnifunc "ale#completion#OmniFunc")
(set vim.g.ale_fix_on_save 1)
(set vim.g.ale_floating_preview 1)
(set vim.g.ale_floating_window_border
     ["│" "─" "╭" "╮" "╯" "╰" "│" "─"])
(vim.keymap.set :n :gd "<Plug>(ale_go_to_definition)" {:noremap true})
(vim.keymap.set :n :gr "<Plug>(ale_find_references)" {:noremap true})
(vim.keymap.set :n :K "<Plug>(ale_hover)" {:noremap true})
(vim.keymap.set :n :<C-k> "<Plug>(ale_previous_wrap)" {:silent true})
(vim.keymap.set :n :<C-j> "<Plug>(ale_next_wrap)" {:silent true})


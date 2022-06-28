(vim.cmd "colorscheme paramount")

;; clear background
(let [l [:Normal :htmlH1 :htmlH2 :htmlH3 :htmlH4 :htmlH5 :htmlH6]]
  (each [_ v (ipairs l)]
    (vim.cmd (.. "highlight " v " ctermbg=None"))))

(set vim.g.mapleader " ")

(vim.keymap.set :n "\\\\" ":write<cr>" {:noremap true})
(vim.keymap.set :i "\\\\" "<esc>:write<cr>" {:noremap true})

(vim.keymap.set :n "<leader>/" ":nohlsearch<cr>" opts)

(let [opts {:noremap true :silent true}]
  (vim.keymap.set :n "<leader>e" vim.diagnostic.open_float opts)
  (vim.keymap.set :n "[d" vim.diagnostic.goto_prev opts)
  (vim.keymap.set :n "]d" vim.diagnostic.goto_next opts)
  (vim.keymap.set :n "<leader>q" vim.diagnostic.setloclist opts))

(fn on_attach [client bufnr]
  (vim.api.nvim_buf_set_option bufnr :omnifunc "v:lua.vim.lsp.omnifunc")
  (let [bufopts {:noremap true :silent true :buffer bufnr}]
    (vim.keymap.set :n "gD" vim.lsp.buf.declaration bufopts)
    (vim.keymap.set :n "gd" vim.lsp.buf.definition bufopts)
    (vim.keymap.set :n "K" vim.lsp.buf.hover bufopts)
    (vim.keymap.set :n "gi" vim.lsp.buf.implementation bufopts)
    (vim.keymap.set :n "<C-k>" vim.lsp.buf.signature_help bufopts)
    (vim.keymap.set :n "<leader>wa" vim.lsp.buf.add_workspace_folder bufopts)
    (vim.keymap.set :n "<leader>wr" vim.lsp.buf.remove_workspace_folder bufopts)
    (vim.keymap.set :n "<leader>wl" (fn [] (print (vim.inspect (vim.lsp.buf.list_workspace_folders)))) bufopts)
    (vim.keymap.set :n "<leader>D" vim.lsp.buf.type_definition bufopts)
    (vim.keymap.set :n "<leader>rn" vim.lsp.buf.rename bufopts)
    (vim.keymap.set :n "<leader>ca" vim.lsp.buf.code_action bufopts)
    (vim.keymap.set :n "gr" vim.lsp.buf.references bufopts)
    (vim.keymap.set :n "<leader>f" vim.lsp.buf.formatting bufopts)))

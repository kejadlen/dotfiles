(vim.cmd "colorscheme paramount")

(set vim.opt.list true)
(set vim.opt.listchars "tab:\\u21e5 ,trail:\\u2423,extends:\\u21c9,precedes:\\u21c7,nbsp:\\u00b7")
(set vim.opt.number true)

(set vim.g.mapleader " ")

(vim.keymap.set :n "\\\\" ":write<cr>" {:noremap true})
(vim.keymap.set :i "\\\\" "<esc>:write<cr>" {:noremap true})

(vim.keymap.set :n :<leader>/ ":nohlsearch<cr>" opts)

;; restore cursor location
;;
;; https://github.com/vim/vim/blob/master/runtime/defaults.vim#L108
(let [{: nvim_command : nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :nvim-startup {})
      cb (fn []
           (when (and
                   (>= (vim.fn.line "'\"") 1)
                   (<= (vim.fn.line "'\"") (vim.fn.line "$"))
                   (not (string.find vim.bo.filetype "commit")))
                 (nvim_command "normal! g`\"")))]
  ;; when restoring the cursor, we want to ignore commit filetypes, so
  ;; we need to manually enable filetype detection to set up those
  ;; autocommands before creating the autocommand to restore the cursor
  ;;
  ;; https://github.com/neovim/neovim/issues/15536#issuecomment-909331778
  (nvim_command "filetype plugin indent on")
  (nvim_create_autocmd :BufReadPost {:callback cb :group au-group}))

;; ftplugins in fennel
;;
;; https://github.com/rktjmp/hotpot.nvim/discussions/41#discussioncomment-3050564
(let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :hotpot-ft {})
      cb #(pcall require (.. :ftplugin. (vim.fn.expand :<amatch>)))]
  (nvim_create_autocmd :FileType {:callback cb :group au-group}))

;; ale

(set vim.g.ale_fix_on_save 1)
(set vim.g.ale_floating_preview 1)

;; lspconfig
; (let [opts {:noremap true :silent true}]
;   (vim.keymap.set :n :<leader>e vim.diagnostic.open_float opts)
;   (vim.keymap.set :n "[d" vim.diagnostic.goto_prev opts)
;   (vim.keymap.set :n "]d" vim.diagnostic.goto_next opts)
;   (vim.keymap.set :n :<leader>q vim.diagnostic.setloclist opts))

; (fn on_attach [client bufnr]
;   (vim.api.nvim_buf_set_option bufnr :omnifunc "v:lua.vim.lsp.omnifunc")
;   (let [bufopts {:noremap true :silent true :buffer bufnr}]
;     (vim.keymap.set :n :gD vim.lsp.buf.declaration bufopts)
;     (vim.keymap.set :n :gd vim.lsp.buf.definition bufopts)
;     (vim.keymap.set :n :K vim.lsp.buf.hover bufopts)
;     (vim.keymap.set :n :gi vim.lsp.buf.implementation bufopts)
;     (vim.keymap.set :n :<C-k> vim.lsp.buf.signature_help bufopts)
;     (vim.keymap.set :n :<leader>wa vim.lsp.buf.add_workspace_folder bufopts)
;     (vim.keymap.set :n :<leader>wr vim.lsp.buf.remove_workspace_folder bufopts)
;     (vim.keymap.set :n :<leader>wl
;                     (fn []
;                       (print (vim.inspect (vim.lsp.buf.list_workspace_folders))))
;                     bufopts)
;     (vim.keymap.set :n :<leader>D vim.lsp.buf.type_definition bufopts)
;     (vim.keymap.set :n :<leader>rn vim.lsp.buf.rename bufopts)
;     (vim.keymap.set :n :<leader>ca vim.lsp.buf.code_action bufopts)
;     (vim.keymap.set :n :gr vim.lsp.buf.references bufopts)
;     (vim.keymap.set :n :<leader>f vim.lsp.buf.formatting bufopts)))

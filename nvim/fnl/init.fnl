(vim.cmd "colorscheme paramount")

(set vim.opt.list true)

;; fnlfmt: skip
(set vim.opt.listchars {:tab      "\\u21e5 "
                        :trail    "\\u2423"
                        :extends  "\\u21c9"
                        :precedes "\\u21c7"
                        :nbsp     "\\u00b7"})

(set vim.opt.number true)

(set vim.g.mapleader " ")

;; move the cursor to the first non-blank character with H
(vim.keymap.set :n :H "^" {:noremap true})

;; quick save
(vim.keymap.set :n "\\\\" ":write<cr>" {:noremap true})
(vim.keymap.set :i "\\\\" "<esc>:write<cr>" {:noremap true})

;; clear highlight
(vim.keymap.set :n :<leader>/ ":nohlsearch<cr>" {:noremap true})

;;; restore cursor location

;; https://github.com/vim/vim/blob/master/runtime/defaults.vim#L108
(let [{: nvim_command : nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :nvim-startup {})
      cb (fn []
           (when (and (< 0 (vim.fn.line "'\""))
                      (<= (vim.fn.line "'\"") (vim.fn.line "$"))
                      (not (string.find vim.bo.filetype :commit)))
             (nvim_command "normal! g`\"")))]
  ;; when restoring the cursor, we want to ignore commit filetypes, so
  ;; we need to manually enable filetype detection to set up those
  ;; autocommands before creating the autocommand to restore the cursor
  ;;
  ;; https://github.com/neovim/neovim/issues/15536#issuecomment-909331778
  (nvim_command "filetype plugin indent on")
  (nvim_create_autocmd :BufReadPost {:callback cb :group au-group}))

;;; ftplugins in fennel

;; https://github.com/rktjmp/hotpot.nvim/discussions/41#discussioncomment-3050564
(let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :hotpot-ft {})
      cb #(pcall require (.. :ftplugin. (vim.fn.expand :<amatch>)))]
  (nvim_create_autocmd :FileType {:callback cb :group au-group}))

;; (require :ale)
(require :fzf)

;;; lint

(let [lint (require :lint)
      {: linters :linters_by_ft linters-by-ft :try_lint try-lint} lint
      {:fennel fennel-linter} linters
      {: nvim_create_autocmd} vim.api]
  (tset linters-by-ft :fennel [:fennel])
  (tset fennel-linter :globals [:vim]) ; hack
  (nvim_create_autocmd :BufWritePost {:callback #(try-lint)}))

;;; lspconfig

;; (vim.lsp.set_log_level :debug)

(let [opts {:noremap true :silent true}]
  (vim.keymap.set :n :<leader>e vim.diagnostic.open_float opts)
  (vim.keymap.set :n "[d" vim.diagnostic.goto_prev opts)
  (vim.keymap.set :n "]d" vim.diagnostic.goto_next opts)
  (vim.keymap.set :n :<leader>q vim.diagnostic.setloclist opts))

(fn on_attach [client bufnr]
  (vim.api.nvim_buf_set_option bufnr :omnifunc "v:lua.vim.lsp.omnifunc")
  (let [bufopts {:noremap true :silent true :buffer bufnr}]
    (vim.keymap.set :n :gD vim.lsp.buf.declaration bufopts)
    (vim.keymap.set :n :gd vim.lsp.buf.definition bufopts)
    (vim.keymap.set :n :K vim.lsp.buf.hover bufopts)
    (vim.keymap.set :n :gi vim.lsp.buf.implementation bufopts)
    (vim.keymap.set :n :<C-k> vim.lsp.buf.signature_help bufopts)
    (vim.keymap.set :n :<leader>wa vim.lsp.buf.add_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wr vim.lsp.buf.remove_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wl
                    (fn []
                      (print (vim.inspect (vim.lsp.buf.list_workspace_folders))))
                    bufopts)
    (vim.keymap.set :n :<leader>D vim.lsp.buf.type_definition bufopts)
    (vim.keymap.set :n :<leader>rn vim.lsp.buf.rename bufopts)
    (vim.keymap.set :n :<leader>ca vim.lsp.buf.code_action bufopts)
    (vim.keymap.set :n :gr vim.lsp.buf.references bufopts)
    (vim.keymap.set :n :<leader>f vim.lsp.buf.formatting bufopts)))

(let [{: rust_analyzer} (require :lspconfig)]
  ((. rust_analyzer :setup) {: on_attach
                             :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}}))

;;; netrw

(set vim.g.netrw_fastbrowse 0)

; https://github.com/tpope/vim-vinegar/issues/13
(set vim.g.netrw_home "~/.nvim_tmp")

;;; tree-sitter

(let [configs (require :nvim-treesitter.configs)
      {: setup} configs]
  (setup {:ensure_installed [:fennel]
          :sync_install false
          :highlight {:enable true :additional_vim_regex_highlighting false}
          :indent {:enable true}}))
(set vim.opt.foldmethod :expr)
(set vim.opt.foldexpr "nvim_treesitter#foldexpr()")

;;; generate help files

; Load all plugins now.
; Plugins need to be added to runtimepath before helptags can be generated.
(vim.api.nvim_command :packloadall)

; Load all of the helptags now, after plugins have been loaded.
; All messages and errors will be ignored.
(vim.api.nvim_command "silent! helptags ALL")

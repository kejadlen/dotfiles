(vim.cmd "colorscheme paramount")

(set vim.opt.foldlevel 1)
(set vim.opt.linebreak true)
(set vim.opt.list true)

;; fnlfmt: skip
(set vim.opt.listchars {:tab      "\\u21e5 "
                        :trail    "\\u2423"
                        :extends  "\\u21c9"
                        :precedes "\\u21c7"
                        :nbsp     "\\u00b7"})

(set vim.opt.number true)
(set vim.opt.showmode false)
(set vim.opt.termguicolors true)
(set vim.opt.virtualedit :block)
(set vim.opt.wildmode "longest:full")

;; search
(set vim.opt.gdefault true)
(set vim.opt.ignorecase true)
(set vim.opt.smartcase true)

(set vim.g.mapleader " ")

;; disable arrow keys
(each [_ v (ipairs [:up :down :left :right])]
  (vim.keymap.set :n (.. "<" v ">") :<nop>))

;; quick save
(vim.keymap.set :n "\\\\" ":write<cr>")
(vim.keymap.set :i "\\\\" "<esc>:write<cr>")

;; clear highlight
(vim.keymap.set :n :<leader>/ ":nohlsearch<cr>")

;; non-shifted shortcuts for moving the cursor to the start/end of the current line
(vim.keymap.set :n :H "^")
(vim.keymap.set :n :L "$")

;; re-run the last macro
(vim.keymap.set :n :Q "@@")

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

;;; diagnostic

(vim.diagnostic.config {:float {:source :if_many :border :rounded}})

(require :fzf)

;;; lightline

;; https://github.com/itchyny/lightline.vim/issues/168#issuecomment-232183744
(let [colorscheme :powerline
      palette-key (.. "lightline#colorscheme#" colorscheme "#palette")
      palette (. vim.g palette-key)]
  (set vim.g.lightline {: colorscheme})
  (each [_ f (ipairs [:normal :inactive :tabline])]
    (tset palette f :middle [[:NONE :NONE :NONE :NONE]]))
  (tset vim.g palette-key palette))

;;; lint

(let [lint (require :lint)
      {: linters :linters_by_ft linters-by-ft :try_lint try-lint} lint
      {:fennel fennel-linter} linters
      {: nvim_create_autocmd} vim.api]
  (tset linters-by-ft :fennel [:fennel])
  (tset fennel-linter :globals [:vim :hs :spoon]) ; hack for neovim and hammerspoon
  (nvim_create_autocmd :BufWritePost {:callback #(try-lint)}))

;;; lspconfig

;; (vim.lsp.set_log_level :debug)

(let [opts {:noremap true :silent true}]
  (vim.keymap.set :n :<leader>e vim.diagnostic.open_float opts)
  (vim.keymap.set :n "[d" vim.diagnostic.goto_prev opts)
  (vim.keymap.set :n "]d" vim.diagnostic.goto_next opts)
  (vim.keymap.set :n :<leader>q vim.diagnostic.setloclist opts))

(fn on-attach [client bufnr]
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
    (vim.keymap.set :n :<leader>lf vim.lsp.buf.formatting bufopts)))

(let [{: efm : rust_analyzer : tsserver} (require :lspconfig)]
  ((. efm :setup) {:on_attach on-attach
                   :init_options {:documentFormatting true
                                  :hover true
                                  :documentSymbol true
                                  :codeAction true
                                  :completion true}
                   :settings {:languages {:javascript [{:formatCommand "prettier --stdin-filepath ${INPUT}"
                                                        :formatStdin true}]
                                          :typescript [{:formatCommand "prettier --stdin-filepath ${INPUT}"
                                                        :formatStdin true}]}}
                   :filetypes [:javascript :typescript]})
  ((. rust_analyzer :setup) {:on_attach on-attach
                             :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})
  ((. tsserver :setup) {:on_attach (fn [client bufnr]
                                      (on-attach client bufnr)
                                      (set client.resolved_capabilities.document_formatting
                                           false))}))

;;; netrw

;; https://github.com/tpope/vim-vinegar/issues/13
(set vim.g.netrw_fastbrowse 0)
(set vim.g.netrw_home "~/.nvim_tmp")

;;; treesitter
(let [configs (require :nvim-treesitter.configs)
      {: setup} configs]
  (setup {:ensure_installed [:fennel]
          :sync_install false
          :highlight {:enable true :additional_vim_regex_highlighting false}
          :indent {:enable true}
          :incremental_selection {:enable true
                                  :keymaps {:init_selection :gnn
                                            :node_incremental :grn
                                            :scope_incremental :grc
                                            :node_decremental :grm}}}))

(set vim.opt.foldmethod :expr)
(set vim.opt.foldexpr "nvim_treesitter#foldexpr()")

;;; generate help files

;; Load all plugins now.
;; Plugins need to be added to runtimepath before helptags can be generated.
(vim.api.nvim_command :packloadall)

;; Load all of the helptags now, after plugins have been loaded.
;; All messages and errors will be ignored.
(vim.api.nvim_command "silent! helptags ALL")

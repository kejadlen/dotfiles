(vim.cmd "colorscheme paramount")

(set vim.o.cmdheight 0)

(set vim.o.foldlevel 2)
(set vim.o.linebreak true)
(set vim.o.list true)
(set vim.o.listchars
     "tab:\\u21e5 ,trail:\\u2423,extends:\\u21c9,precedes:\\u21c7,nbsp:\\u00b7")

(set vim.o.number true)
(set vim.o.showmode false)
(set vim.o.termguicolors true)
(set vim.o.virtualedit :block)
(set vim.o.wildmode "longest:full")

;; search
(set vim.o.gdefault true)
(set vim.o.ignorecase true)
(set vim.o.smartcase true)

(set vim.g.mapleader " ")

;; disable arrow keys
(each [_ v (ipairs [:up :down :left :right])]
  (vim.keymap.set :n (.. "<" v ">") :<nop>))

;; quick save
(vim.keymap.set :n "\\\\" ":write<cr>")
(vim.keymap.set :i "\\\\" "<esc>:write<cr>")

;; highlight
(set vim.o.hlsearch true)
(vim.keymap.set :n :<leader>/ ":nohlsearch<cr>")
(let [{: nvim_command : nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :nvim-hl-on-yank {})
      cb #(vim.highlight.on_yank {:higroup :Search :timeout 250})]
  (nvim_create_autocmd :TextYankPost {:callback cb :group au-group}))

;; non-shifted shortcuts for moving the cursor to the start/end of the current line
(vim.keymap.set :n :H "^")
(vim.keymap.set :n :L "$")

;; re-run the last macro
(vim.keymap.set :n :Q "@@")

;; completion

(set vim.o.completeopt "longest,menuone")

;; smart tab
;; https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
(vim.keymap.set :i :<tab>
                (fn []
                  (let [line (vim.fn.getline ".")
                        col (vim.fn.col ".")
                        line (line:sub 1 (- col 1))
                        substr (line:match "[^ \t]*$")]
                    (if (= (substr:len) 0) :<tab> :<c-x><c-o>)))
                {:expr true})

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

;;; filetype

(set vim.g.do_filetype_lua true)

;;; ftplugins in fennel

;; https://github.com/rktjmp/hotpot.nvim/discussions/41#discussioncomment-3050564
(let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :hotpot-ft {})
      cb #(pcall require (.. :ftplugin. (vim.fn.expand :<amatch>)))]
  (nvim_create_autocmd :FileType {:callback cb :group au-group}))

(require :fzf)
(require :lsp)

;;; diagnostic

(vim.diagnostic.config {:float {:source :if_many :border :rounded}})

;;; hotpot

(require :hp)

;;; lightline

;; https://github.com/itchyny/lightline.vim/issues/168#issuecomment-232183744
(let [colorscheme :powerline
      component {:filename "%{expand(\"%:~:.\")}"} ; relative path
      palette-key (.. "lightline#colorscheme#" colorscheme "#palette")
      palette (. vim.g palette-key)]
  (set vim.g.lightline {: colorscheme : component})
  (each [_ f (ipairs [:normal :inactive :tabline])]
    (tset palette f :middle [[:NONE :NONE :NONE :NONE]]))
  (tset vim.g palette-key palette))

;;; navic

;; TODO Enable this when 0.8 is released
;; TODO Use fennel for this?
; (set vim.o.winbar "%{%v:lua.require'nvim-navic'.get_location()%}")

;;; netrw

;; https://github.com/tpope/vim-vinegar/issues/13
(set vim.g.netrw_fastbrowse 0)
(set vim.g.netrw_home "~/.nvim_tmp")

;;; treesitter
(let [configs (require :nvim-treesitter.configs)
      {: setup} configs]
  (setup {:ensure_installed [:fennel :hcl :lua :python :query :ruby :rust :typescript]
          :sync_install false
          :highlight {:enable true :additional_vim_regex_highlighting false}
          ;; disabling since this is super annoying in Ruby
          ; :indent {:enable true}
          :incremental_selection {:enable true
                                  :keymaps {:init_selection :gnn
                                            :node_incremental :grn
                                            :scope_incremental :grc
                                            :node_decremental :grm}}
          :textobjects {:select {:enable true
                                 :lookahead true
                                 :keymaps {:af "@function.outer"
                                           :if "@function.inner"
                                           :ac "@class.outer"
                                           :ic "@class.inner"
                                           :ab "@block.outer"
                                           :ib "@block.inner"
                                           :aa "@parameter.outer"
                                           :ia "@parameter.inner"}}}}))

(set vim.o.foldmethod :expr)
(set vim.o.foldexpr "nvim_treesitter#foldexpr()")

;;; generate help files

;; Load all plugins now.
;; Plugins need to be added to runtimepath before helptags can be generated.
(vim.api.nvim_command :packloadall)

;; Load all of the helptags now, after plugins have been loaded.
;; All messages and errors will be ignored.
(vim.api.nvim_command "silent! helptags ALL")


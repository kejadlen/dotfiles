(vim.cmd.colorscheme :paramount)

(set vim.o.cmdheight 0)

(set vim.o.foldlevel 1)
(set vim.o.foldminlines 2)
(set vim.o.linebreak true)
(set vim.o.list true)
(set vim.o.listchars "tab:⇥ ,trail:␣,extends:⇉,precedes:⇇,nbsp:·")

(set vim.o.number true)
(set vim.o.showmode false)
(set vim.o.termguicolors true)
(set vim.o.virtualedit :block)
(set vim.o.wildmode "longest:full")

;; search
(set vim.o.gdefault true)
(set vim.o.ignorecase true)
(set vim.o.smartcase true)

(set vim.o.mouse nil)

;;; completion

(set vim.o.completeopt "longest,menuone")

;; gui
(set vim.o.guifont "Source Code Pro")

(set vim.g.markdown_fenced_languages [:ts=typescript])

;;; mappings

(set vim.g.mapleader " ")

;; disable arrow keys
(each [_ v (ipairs [:up :down :left :right])]
  (vim.keymap.set :n (.. "<" v ">") :<nop>))

;; command mode
(vim.keymap.set :c :<c-a> :<home>)

;; quick save
(vim.keymap.set :n "\\\\" ":write<cr>")
(vim.keymap.set :i "\\\\" "<esc>:write<cr>")

;; highlight
(set vim.o.hlsearch true)
(vim.keymap.set :n :<leader>/ ":nohlsearch<cr>")
(let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :nvim-hl-on-yank {})
      cb #(vim.highlight.on_yank {:higroup :Search :timeout 100})]
  (nvim_create_autocmd :TextYankPost {:callback cb :group au-group}))

;; non-shifted shortcuts for moving the cursor to the start/end of the current line
(vim.keymap.set :n :H "^")
(vim.keymap.set :n :L "$")

;; re-run the last macro
(vim.keymap.set :n :Q "@@")

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

(vim.filetype.add {:extension {:ua :uiua}})

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

;;; netrw

;; https://github.com/tpope/vim-vinegar/issues/13
(set vim.g.netrw_fastbrowse 0)
(set vim.g.netrw_home "~/.nvim_tmp")

;;; treesitter
(let [{: treesitter} vim
      {: setup} (require :nvim-treesitter.configs)]
  (setup {:ensure_installed [:fennel
                             :hcl
                             :lua
                             :python
                             :query
                             :ruby
                             :rust
                             :terraform
                             :typescript
                             :yaml]
          :sync_install false
          :highlight {:enable true :additional_vim_regex_highlighting false}
          ;; disabling since this is super annoying in Ruby
          ; :indent {:enable true}
          :incremental_selection {:enable true
                                  :keymaps {:init_selection :gnn
                                            :node_incremental :grn
                                            :scope_incremental :grc
                                            :node_decremental :grm}}
          :textobjects {:move {:enable true
                               :set_jumps true
                               :goto_next_start {"]f" "@function.outer"
                                                 "]b" "@block.outer"
                                                 "]a" "@parameter.inner"}
                               :goto_next_end {"]F" "@function.outer"
                                               "]B" "@block.outer"
                                               "]A" "@parameter.inner"}
                               :goto_previous_start {"[f" "@function.outer"
                                                     "[b" "@block.outer"
                                                     "[a" "@parameter.inner"}
                               :goto_previous_end {"[F" "@function.outer"
                                                   "[B" "@block.outer"
                                                   "[A" "@parameter.inner"}}
                        :select {:enable true
                                 :lookahead true
                                 :keymaps {:af "@function.outer"
                                           :if "@function.inner"
                                           :ac "@class.outer"
                                           :ic "@class.inner"
                                           :ab "@block.outer"
                                           :ib "@block.inner"
                                           :aa "@parameter.outer"
                                           :ia "@parameter.inner"}}}})
  (treesitter.language.register :yaml :yaml.ansible)
  (treesitter.query.set :python :folds "[
  (function_definition)
  (class_definition)
  (block)
] @fold
[
  (import_statement)
  (import_from_statement)
]+ @fold"))

(let [tscontext (require :treesitter-context)]
  (tscontext.setup))

(set vim.o.foldmethod :expr)
(set vim.o.foldexpr "nvim_treesitter#foldexpr()")

;;; neovide

;; disable animation
(set vim.g.neovide_cursor_animation_length 0)

;;; fidget
(let [{: setup} (require :fidget)] (setup))

;; dirvish

(set vim.g.dirvish_mode ":sort ,^.*[\\/],")

;; indent-blankline

(let [{: setup} (require :ibl)] (setup))

;;; generate help files

;; Load all plugins now.
;; Plugins need to be added to runtimepath before helptags can be generated.
(vim.api.nvim_command :packloadall)

;; Load all of the helptags now, after plugins have been loaded.
;; All messages and errors will be ignored.
(vim.api.nvim_command "silent! helptags ALL")

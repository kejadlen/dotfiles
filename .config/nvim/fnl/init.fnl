(local {:nvim_buf_get_mark nvim-buf-get-mark
        :nvim_buf_line_count nvim-buf-line-count
        :nvim_command nvim-command
        :nvim_create_augroup nvim-create-augroup
        :nvim_create_autocmd nvim-create-autocmd
        :nvim_feedkeys nvim-feedkeys
        :nvim_get_current_win nvim-get-current-win
        :nvim_set_hl nvim-set-hl} vim.api)

;;; colorscheme (toggle between these to compare)
;; Option 1: paramount
(vim.pack.add ["https://git.kejadlen.dev/alpha/vim-colors-paramount.git"])
; (vim.cmd.colorscheme :paramount)
;; Option 2: alphabaster
(vim.cmd.colorscheme :alphabaster)

(set vim.o.cmdheight 0)

;; ui things
(set vim.o.diffopt "inline:char")
(set vim.o.foldlevelstart 4)
(set vim.o.foldminlines 2)
(set vim.o.linebreak true)
(set vim.o.list true)
(set vim.o.listchars "tab:⇥ ,trail:␣,extends:⇉,precedes:⇇,nbsp:·")
(set vim.o.number true)
(set vim.o.showmode false)
(set vim.o.termguicolors true)
(set vim.o.virtualedit :block)
(set vim.o.wildmode "longest:full")
(set vim.o.winborder :rounded)

;; search
(set vim.o.gdefault true)
(set vim.o.ignorecase true)
(set vim.o.smartcase true)

;; completion
(set vim.o.completeopt "nearest,longest,menuone")

;; gui
(set vim.o.mouse nil)
(set vim.o.guifont "Source Code Pro")

;; misc
(set vim.g.markdown_fenced_languages [:ts=typescript])
(set vim.o.undofile true)

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
(let [group (nvim-create-augroup :nvim-hl-on-yank {})
      callback #(vim.highlight.on_yank {:higroup :Search :timeout 100})]
  (nvim-create-autocmd :TextYankPost {: callback : group}))

;; non-shifted shortcuts for moving the cursor to the start/end of the current line
(vim.keymap.set :n :H "^")
(vim.keymap.set :n :L "$")

;; re-run the last macro
(vim.keymap.set :n :Q "@@")

;; smart tab
;; https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
(vim.keymap.set :i :<tab>
                #(let [line (vim.fn.getline ".")
                       col (vim.fn.col ".")
                       line (line:sub 1 (- col 1))
                       substr (line:match "[^ \t]*$")]
                   (if (= (substr:len) 0) :<tab> :<c-x><c-o>))
                {:expr true})

;;; restore cursor location

;; Restore cursor position when re-opening a file:
;;   https://github.com/neovim/neovim/issues/16339#issuecomment-1457394370
;;
;; See also (previously):
;;   https://github.com/vim/vim/blob/master/runtime/defaults.vim#L108
(let [restore-cursor-position (fn [opts]
                                (let [ft (. (. vim.bo opts.buf) :filetype)
                                      last-pos (nvim-buf-get-mark opts.buf "\"")
                                      last-known-line (. last-pos 1)]
                                  (when (and (not (or (ft:match :commit)
                                                      (ft:match :rebase)))
                                             (> last-known-line 1)
                                             (<= last-known-line
                                                 (nvim-buf-line-count opts.buf)))
                                    (nvim-feedkeys "g`\"" :nx false))))
      setup-cursor-restore (fn [opts]
                             (nvim-create-autocmd :BufWinEnter
                                                  {:once true
                                                   :buffer opts.buf
                                                   :callback #(restore-cursor-position opts)}))]
  (nvim-create-autocmd :BufRead {:callback setup-cursor-restore}))

;;; filetype

(vim.filetype.add {:extension {:ua :uiua}})

;;; vim.pack

;; :lua vim.pack.update({ 'nvim-lspconfig' })
;; :lua vim.pack.update(nil, { target = 'lockfile' })
(vim.pack.add [;; was using jaawerth/fennel.vim, but there are some annoyances
               ;; with it, so let's try this one instead
               "https://github.com/atweiden/vim-fennel.git"
               "https://github.com/christoomey/vim-tmux-navigator.git"
               "https://github.com/direnv/direnv.vim.git"
               "https://github.com/hashivim/vim-terraform.git"
               "https://github.com/itchyny/lightline.vim.git"
               "https://github.com/j-hui/fidget.nvim.git"
               "https://github.com/junegunn/fzf.git"
               "https://github.com/junegunn/fzf.vim.git"
               {:src "https://github.com/lukas-reineke/indent-blankline.nvim.git"
                :version :v3.9.1}
               {:src "https://github.com/neovim/nvim-lspconfig.git"
                :version (vim.version.range :v2.8.0)}
               {:src "https://github.com/nvim-treesitter/nvim-treesitter.git"
                :version :main}
               "https://github.com/nvim-treesitter/nvim-treesitter-context.git"
               {:src "https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git"
                :version :main}
               ;; here for completeness, but actually added in init.lua for bootstrapping purposes
               ; "https://github.com/rktjmp/hotpot.nvim.git"
               "https://github.com/suy/vim-context-commentstring.git"
               "https://github.com/tpope/vim-abolish.git"
               "https://github.com/tpope/vim-dispatch.git"
               "https://github.com/tpope/vim-repeat.git"
               "https://github.com/tpope/vim-obsession.git"
               "https://github.com/tpope/vim-sensible.git"
               "https://github.com/tpope/vim-sleuth.git"
               "https://github.com/tpope/vim-speeddating.git"
               "https://github.com/tpope/vim-surround.git"
               "https://github.com/tpope/vim-unimpaired.git"
               "https://github.com/tpope/vim-vinegar.git"])

(let [callback (fn [event]
                 (let [{:spec {: name} : kind} event.data]
                   ;; Run :TSUpdate after updating nvim-treesitter
                   (when (and (= name :nvim-treesitter)
                              (or (= kind :install) (= kind :update)))
                     (if (not event.data.active)
                         ;; packadd is required because PackChanged fires before the plugin
                         ;; is loaded, so :TSUpdate wouldn't be available otherwise
                         (vim.cmd.packadd :nvim-treesitter))
                     (vim.cmd.TSUpdate))))]
  (nvim-create-autocmd :PackChanged {: callback}))

(require :fzf)
(require :lsp)

;;; diagnostic

(vim.diagnostic.config {:float {:source :if_many :border :rounded}})

;;; hotpot

(require :hp)

;;; lightline

;; https://github.com/itchyny/lightline.vim/issues/168#issuecomment-232183744
;; Option 1: powerline theme (for paramount)
(let [colorscheme :powerline
      component {:filename "%{expand(\"%:~:.\")}"} ; relative path
      palette-key (.. "lightline#colorscheme#" colorscheme "#palette")
      palette (. vim.g palette-key)]
  (set vim.g.lightline {: colorscheme : component})
  (each [_ f (ipairs [:normal :inactive :tabline])]
    (tset palette f :middle [[:NONE :NONE :NONE :NONE]]))
  (tset vim.g palette-key palette))

;; Option 2: alphabaster theme (uncomment when using alphabaster colorscheme)
; (let [alphabaster-ll (require :alphabaster.lightline)]
;   (alphabaster-ll.setup)
;   (set vim.g.lightline {:colorscheme :alphabaster
;                         :component {:filename "%{expand(\"%:~:.\")}"}}))

;;; netrw

;; https://github.com/tpope/vim-vinegar/issues/13
(set vim.g.netrw_fastbrowse 0)
(set vim.g.netrw_home "~/.nvim_tmp")

;;; treesitter
(require :treesitter)

;; https://neovim.io/doc/user/lsp.html#vim.lsp.foldexpr()
(set vim.o.foldmethod :expr)
;; Default to treesitter folding
(set vim.o.foldexpr "v:lua.vim.treesitter.foldexpr()")
;; Prefer LSP folding if client supports it
(let [callback #(let [client (vim.lsp.get_client_by_id $1.data.client_id)
                      current-win (nvim-get-current-win)]
                  (when (client:supports_method :textDocument/foldingRange)
                    (tset (. vim.wo current-win) 0 :foldexpr
                          "v:lua.vim.lsp.foldexpr()")))]
  (nvim-create-autocmd :LspAttach {: callback}))

;;; focus dimming
;; Fade the background when neovim loses focus (matches tmux pane-focus-out behavior).
;; FocusLost/FocusGained fire when the terminal pane loses/gains focus.
(let [group (nvim-create-augroup :focus-dim {})
      {: colors} (require :alphabaster.palette)
      dim-bg #(nvim-set-hl 0 :Normal {:fg colors.fg :bg colors.dim-bg})
      restore-bg #(nvim-set-hl 0 :Normal {:fg colors.fg :bg colors.bg})]
  (nvim-create-autocmd :FocusLost {:callback dim-bg : group})
  (nvim-create-autocmd :FocusGained {:callback restore-bg : group}))

;;; neovide

;; disable animation
(set vim.g.neovide_cursor_animation_length 0)

;;; plugins

;;; fidget
(let [{: setup} (require :fidget)] (setup))

;; indent-blankline
(let [{: setup} (require :ibl)] (setup))

;; mini.align
; (let [{: setup} (require :mini.align)] (setup))

;;; generate help files

;; Load all plugins now.
;; Plugins need to be added to runtimepath before helptags can be generated.
(nvim-command :packloadall)

;; Load all of the helptags now, after plugins have been loaded.
;; All messages and errors will be ignored.
(nvim-command "silent! helptags ALL")

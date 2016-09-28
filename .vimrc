set nocompatible

if filereadable(glob("~/.vimrc.before"))
  source ~/.vimrc.before
endif

" pathogen
filetype off
if empty($GOPATH)
  let g:pathogen_disabled = []
  call add(g:pathogen_disabled, 'go')
endif
execute pathogen#infect()

""" mappings

let mapleader="\<Space>"
noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>

nnoremap ' `
nnoremap ` '
" nnoremap \ ,
nnoremap Y y$
nnoremap <leader>/ :noh<cr>
" nnoremap gt :exec tabpagenr('$') == 1 ? 'bn' : 'tabnext'<cr>
" nnoremap gT :exec tabpagenr('$') == 1 ? 'bp' : 'tabprevious'<cr>
" nnoremap <C-n> :exec tabpagenr('$') == 1 ? 'bn' : 'tabnext'<cr>
" nnoremap <C-p> :exec tabpagenr('$') == 1 ? 'bp' : 'tabprevious'<cr>
cnoremap w!! w !sudo tee % > /dev/null
" inoremap <bs> <nop>
inoremap <esc> <nop>
inoremap <C-c> <esc>
inoremap <C-[> <esc>
" inoremap jk <esc>
command W w
nnoremap <C-h> <C-w><C-h>
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
nnoremap <C-l> <C-w><C-l>

" don't unindent lines starting with #
inoremap # X#

" don't change the cursor position when joining lines
" nnoremap J mzJ`z

""" buffers

set hidden

" programming
syntax on
set number
set ttyfast
set lazyredraw
set modelines=1

" has to go after syntax enable
let g:solarized_termcolors=256
set background=dark
colorscheme solarized
highlight Normal ctermbg=235
highlight rubyDefine ctermbg=235
set noshowmode

" has to go after solarized, wtf?
highlight LongLine term=reverse cterm=reverse ctermfg=1 guifg=Black guibg=Yellow
match LongLine /\%101v./

" searching
set gdefault
set hlsearch
set ignorecase
set smartcase

" incsearch.vim
augroup incsearch-keymap
    autocmd!
    autocmd VimEnter * call s:incsearch_keymap()
augroup END
function! s:incsearch_keymap()
    IncSearchNoreMap <C-f> <Right>
    IncSearchNoreMap <C-b> <Left>
endfunction
let g:incsearch#auto_nohlsearch = 1
let g:incsearch#consistent_n_direction = 1
let g:incsearch#magic = '\v'
let g:incsearch#emacs_like_keymap = 1
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" encoding
set encoding=utf8
set fileencoding=utf8
set fileformat=unix

" reading
set linebreak
set autoread
" set ttyfast
set list
let &listchars = "tab:\u21e5 ,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"

" autogroups

augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END

if v:version >= 700
  augroup BufferScrolling
    au!
    au BufLeave * if !&diff | let b:winview = winsaveview() | endif
    au BufEnter * if exists('b:winview') && !&diff | call winrestview(b:winview) | unlet! b:winview | endif
  augroup END
endif

" folding
" set foldmethod=indent
set foldlevel=3
" set nofoldenable

" view
set viewdir=$HOME/.vim_view//
" " au BufWinLeave ?* mkview
" au BufWritePost,BufLeave,WinLeave ?* mkview " for tabs
" au BufWinEnter ?* silent loadview

" jump to last cursor position when opening a file
autocmd BufReadPost *
\ if line("'\"") > 0 && line("'\"") <= line("$") |
\   exe "normal g'\"" |
\ endif

" diffing
set diffopt=filler,context:5

" command mode
set undolevels=1000
set wildmode=list:longest

" backup
set nobackup
" set backupdir=$HOME/.vim_backup//
set directory=$HOME/.vim_tmp//

" shell
" set title
" set titleold=

" customize syntax highlighting
" highlight MatchParen cterm=bold ctermbg=none ctermfg=none
" highlight Folded ctermfg=1 ctermbg=NONE
" highlight FoldColumn ctermfg=1 ctermbg=NONE
" highlight clear Search
" highlight Search ctermfg=6 ctermbg=9 term=underline cterm=underline gui=underline

set wildignore+=*.pyc,*/bower_components/*,*/python2.7/*,*/share/doc/*,*/target/*

" blessed silence
set visualbell
" set t_vb

" move into blank spaces in visual block mode
set virtualedit=block

" splits
set splitbelow
set splitright

" scratch
noremap <leader>s :Scratch<cr>
let g:scratchBackupFile='$HOME/.vim/.scratch'

" CtrlP
let g:ctrlp_map = '<leader>p'
let g:ctrlp_match_window='bottom,order:btt,min:1,max:20'
let g:ctrlp_working_path_mode='ra'
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

" Powerline
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup

" vim-projectionist
nnoremap <leader>a :A<cr>

" rust.vim
let g:rustfmt_autosave = 1

" vim-markdown
let g:markdown_fenced_languages = ['ruby']

" gui stuff
set guioptions-=T
set guifont=Consolas:h9:cANSI
set mousehide

" Expand %% into the directory of the current file
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'  

" ripgrep
if executable('rg')
  set grepprg=rg\ --no-heading\ --vimgrep
  set grepformat=%f:%l:%c:%m
endif

" vim-dispatch
nnoremap <leader>d :Dispatch<CR>

if has("gui_running")
  " au GUIEnter * simalt ~x " fullscreen
  " set transparency=10
  set macmeta
  set background=light
  set guifont=Source\ Code\ Pro\ for\ Powerline:h13
  set macligatures
" else
  " fix Command-T's selection in Terminal.app
  " hi Visual term=reverse cterm=reverse ctermfg=187 ctermbg=235 guifg=Black guibg=Yellow
end

if v:version >= 703
  " set relativenumber
  set undofile
  set undodir=$HOME/.vim_undo//
endif

if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif

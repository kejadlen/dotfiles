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
filetype plugin indent on

""" mappings

let mapleader=','
" let maplocalleader='\\'
noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>
nnoremap ' `
nnoremap ` '
" nnoremap \ ,
nnoremap Y y$
nnoremap <leader>/ :noh<cr>
nnoremap gt :exec tabpagenr('$') == 1 ? 'bn' : 'tabnext'<cr>
nnoremap gT :exec tabpagenr('$') == 1 ? 'bp' : 'tabprevious'<cr>
nnoremap <C-n> :exec tabpagenr('$') == 1 ? 'bn' : 'tabnext'<cr>
nnoremap <C-p> :exec tabpagenr('$') == 1 ? 'bp' : 'tabprevious'<cr>
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

" has to go after solarized, wtf?
highlight LongLine term=reverse cterm=reverse ctermfg=1 guifg=Black guibg=Yellow
match LongLine /\%81v./

" searching
set gdefault
set hlsearch
set ignorecase
set smartcase

" encoding
set encoding=utf8
set fileencoding=utf8
set fileformat=unix

" indent/tabbing
" set smartindent
" set expandtab
" set shiftwidth=2
" set softtabstop=2
" set tabstop=2

" reading
set linebreak
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
    au BufEnter * if exists('b:winview') && !&diff | call winrestview(b:winview) | endif
  augroup END
endif

" folding
" set foldmethod=indent
set foldlevel=3
" set nofoldenable

" view
set viewdir=$HOME/.vim_view//
" " au BufWinLeave ?* mkview
au BufWritePost,BufLeave,WinLeave ?* mkview " for tabs
au BufWinEnter ?* silent loadview

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

" ack
set grepprg=ack

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

" Tagbar
nnoremap <silent> <leader>t :TagbarToggle<cr>
let g:tagbar_autoclose=1
let g:tagbar_autofocus=1
let g:tagbar_compact=1

" Command-T
" nnoremap <silent> <leader>f :CommandT<cr>
" let g:CommandTMatchWindowReverse=1

" CtrlP
let g:ctrlp_map = '<leader>p'
let g:ctrlp_match_window='bottom,order:btt,min:1,max:20'
let g:ctrlp_reuse_window='startify'
let g:ctrlp_working_path_mode='ra'

" Startify
let g:startify_change_to_vcs_root = 1

" Gist
let g:gist_detect_filetype=1
let g:gist_open_browser_after_post=1
let g:gist_clip_command = 'pbcopy'

" Gundo
nnoremap <leader>u :GundoToggle<cr>
let g:gundo_preview_bottom=1

" vimwiki
let g:vimwiki_list = [{'path': '~/Dropbox/vimwiki', 'syntax': 'markdown', 'ext': '.md'},
    \                 {'path': '~/Dropbox/simplymeasured/vimwiki', 'syntax': 'markdown', 'ext': '.md'}]
let g:vimwiki_global_ext = 0
nmap <leader>vw <plug>VimwikiIndex
nmap <leader>vwt <plug>VimwikiTabIndex
nmap <leader>vws <plug>VimwikiUISelect
nmap <leader>vwi <plug>VimwikiDiaryIndex
nmap <leader>vw<leader>w <plug>VimwikiMakeDiaryNote
nmap <leader>vw<leader>t <plug>VimwikiTabMakeDiaryNote
nmap <leader>vw<leader>n :VimwikiDiaryNextDay<cr>
nmap <leader>vw<leader>p :VimwikiDiaryPrevDay<cr>
nmap <leader>vw<leader>i <plug>VimwikiDiaryGenerateLinks

" Vimux
" map <leader>vp :VimuxPromptCommand<cr>
" map <leader>vl :VimuxRunLastCommand<cr>
" map <leader>vq :VimuxCloseRunner<cr>

" gui stuff
set guioptions-=T
set guifont=Consolas:h9:cANSI
set mousehide

" quickfix
autocmd QuickFixCmdPost *grep* cwindow

" populate the argument list with each of the files named in the quickfix list
function! QuickfixFilenames()
let buffer_numbers = {}
for quickfix_item in getqflist()
  let buffer_numbers[quickfix_item['bufnr']] =
  bufname(quickfix_item['bufnr'])
endfor
return join(map(values(buffer_numbers), 'fnameescape(v:val)'))
endfunction
command! -nargs=0 -bar Qargs execute 'args' QuickfixFilenames()

" Expand %% into the directory of the current file
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'  

if has("gui_running")
  " au GUIEnter * simalt ~x " fullscreen
  " set transparency=10
  set macmeta
  set background=light
  set guifont=Source\ Code\ Pro\ for\ Powerline:h13
" else
  " fix Command-T's selection in Terminal.app
  " hi Visual term=reverse cterm=reverse ctermfg=187 ctermbg=235 guifg=Black guibg=Yellow
end

if v:version >= 703
  " set relativenumber
  set undofile
  set undodir=$HOME/.vim_undo//

  " omnicomplete
  " set completeopt=longest,menuone
  " inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<cr>"
  " inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  "       \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<cr>'
  " highlight Pmenu ctermbg=grey ctermfg=black
  " highlight PmenuSel ctermbg=magenta ctermfg=black

  " set colorcolumn=81
endif

if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif

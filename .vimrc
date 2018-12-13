" vim:foldmethod=marker:foldlevel=0

" Mappings {{{

let mapleader="\<Space>"

noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>

nnoremap ' `
nnoremap ` '
" nnoremap Y y$
nnoremap H ^
nnoremap L $
nnoremap Q @@
nnoremap <leader>/ :nohlsearch<cr>

" don't unindent lines starting with #
inoremap # X#

nnoremap \\ :write<cr>
inoremap \\ <esc>:write<cr>

" rerun the last command
nnoremap !! :!!<cr>
inoremap !! <esc>:!!<cr>

" }}}

" Commands {{{

set undolevels=1000
set wildmode=list:longest,full

"}}}

" Display {{{

" set t_Co=256
set background=dark
" let g:solarized_termcolors=256
colorscheme paramount

fun! s:highlight()
  " highlight Normal ctermbg=235
  highlight Normal ctermbg=NONE
"   highlight CursorLine ctermbg=236
"   highlight MatchParen ctermbg=238
endfun

augroup MyHighlight
  autocmd!
  autocmd ColorScheme * call s:highlight()
augroup end
call s:highlight()

" highlight LongLine term=reverse cterm=reverse ctermfg=1 guifg=Black guibg=Yellow
" match LongLine /\%101v./

" set foldlevelstart=10
" set foldmethod=indent
set linebreak
set list
let &listchars="tab:\u21e5 ,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"
set number
set ttyfast
set splitbelow
set splitright
set lazyredraw

" only show cursorline in current window
" augroup CursorLine
"   au!
"   au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
"   au WinLeave * setlocal nocursorline
" augroup END

" }}}

" {{{ Folding
set foldclose=all " Close folds if you leave them in any way
" set foldcolumn=1 " Show the foldcolumn
" set foldenable " Turn on folding
set foldlevel=1 " Autofold everything by default
set foldmethod=syntax " Fold on the syntax
set foldnestmax=1 " I only like to fold outer functions
set foldopen=all " Open folds if you touch them in any way
" }}}

" Editing {{{

" set hidden
if !has("nvim")
  set noesckeys
endif
set virtualedit=block
set noshowmode

function! RestoreCursor()
  let pos = line("'\"")
  if pos > 0 && pos <= line("$")
    normal! g`"zz
    return 1
  endif
endfunction

augroup RestoreCursor
  autocmd!
  autocmd BufWinEnter * call RestoreCursor()
augroup end

augroup netrw_buf_hidden_fix
  autocmd!

  " Set all non-netrw buffers to bufhidden=hide
  autocmd BufWinEnter *
        \  if &ft != 'netrw'
        \|     set bufhidden=hide
        \| endif
augroup end

augroup AutoComment
  autocmd FileType * setlocal formatoptions-=o
augroup END

" }}}

" GUI {{{

if has("gui_running")
  " set background=light

  " causes flickering in the terminal for some reason
  set macligatures
end
set guicursor+=a:blinkon0 " disable blinking
set guifont=Source\ Code\ Pro\ for\ Powerline:h13
set guioptions-=T
if has("mac") && !has("nvim")
  set macmeta
endif
set mousehide

" }}}

" Persistence {{{

set directory=~/.vim_tmp
set encoding=utf8
set fileencoding=utf8
set fileformat=unix
set nobackup
set undodir=~/.vim_undo
set undofile

" }}}

" Search {{{

set gdefault
set hlsearch
set ignorecase
set smartcase

" }}}

" Plugins {{{

" incsearch
let g:incsearch#auto_nohlsearch = 1
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" ripgrep
if executable('rg')
  set grepprg=rg\ --no-heading\ --vimgrep
  set grepformat=%f:%l:%c:%m
endif

" projectionist
nnoremap <leader>a :A<cr>

" dispatch
nnoremap <leader>d :Dispatch<cr>

" fzf
if executable('fzf')
  if isdirectory('/usr/local/opt/fzf/plugin')
    set rtp+=/usr/local/opt/fzf
  elseif isdirectory('/home/alpha/.fzf')
    set rtp+=~/.fzf
  endif
  nmap <Leader>b :Buffers<CR>
  nmap <Leader>f :Files<CR>
  nmap <Leader>t :Tags<CR>
endif

" rainbow
let g:rainbow_active = 0

" gundo
nnoremap <leader>u :GundoToggle<CR>

" operator-flashy
map y <Plug>(operator-flashy)
nmap Y <Plug>(operator-flashy)$

" }}}

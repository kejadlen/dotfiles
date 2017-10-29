""" Mappings

let mapleader="\<Space>"

noremap <up> <nop>
noremap <down> <nop>
noremap <left> <nop>
noremap <right> <nop>

nnoremap ' `
nnoremap ` '
nnoremap Y y$
nnoremap <leader>/ :nohlsearch<cr>

" don't unindent lines starting with #
inoremap # X#

""" Commands

set undolevels=1000
set wildmode=list:longest,full

""" Display

set background=dark
let g:solarized_termcolors=256
colorscheme solarized
set background=dark

fun! s:highlight()
  highlight Normal ctermbg=235
endfun

augroup MyHighlight
  autocmd!
  autocmd ColorScheme * call s:highlight()
augroup end
call s:highlight()

" highlight LongLine term=reverse cterm=reverse ctermfg=1 guifg=Black guibg=Yellow
" match LongLine /\%101v./

set foldlevelstart=4
set linebreak
set list
let &listchars="tab:\u21e5 ,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"
set number
" set ttyfast
set splitbelow
set splitright

augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END

""" Editing

" set hidden
if !has("nvim")
  set noesckeys
endif
set virtualedit=block
set noshowmode

function! RestoreCursor()
  if line("'\"") <= line("$")
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

""" GUI

if has("gui_running")
  set background=light

  " causes flickering in the terminal for some reason
  set macligatures
end
set guicursor+=a:blinkon0 " disable blinking
set guifont=Source\ Code\ Pro\ for\ Powerline:h13
set guioptions-=T
if !has("nvim")
  set macmeta
endif
set mousehide

""" Persistence

set directory=~/.vim_tmp
set encoding=utf8
set fileencoding=utf8
set fileformat=unix
set nobackup
set undodir=~/.vim_undo
set undofile

""" Search

set gdefault
set hlsearch
set smartcase

""" Plugins

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
if isdirectory('/usr/local/opt/fzf')
  set rtp+=/usr/local/opt/fzf
  nmap <Leader>b :Buffers<CR>
  nmap <Leader>f :Files<CR>
  nmap <Leader>t :Tags<CR>
endif

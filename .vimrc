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

let g:solarized_termcolors=256
colorscheme solarized
set background=dark
highlight Normal ctermbg=235

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

set noesckeys
set virtualedit=block

function! RestoreCursor()
  if line("'\"") <= line("$")
    normal! g`"zz
    return 1
  endif
endfunction

augroup RestoreCursor
  autocmd!
  autocmd BufWinEnter * call RestoreCursor()
augroup END

""" GUI

if has("gui_running")
  set background=light

  " causes flickering in the terminal for some reason
  set macligatures
end
set guicursor+=a:blinkon0 " disable blinking
set guifont=Source\ Code\ Pro\ for\ Powerline:h13
set guioptions-=T
set macmeta
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

" Powerline
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup

" ripgrep
if executable('rg')
  set grepprg=rg\ --no-heading\ --vimgrep
  set grepformat=%f:%l:%c:%m
endif

""" Selecta

" Run a given vim command on the results of fuzzy selecting from a given shell
" command. See usage below.
function! SelectaCommand(choice_command, selecta_args, vim_command)
  try
    let selection = system(a:choice_command . " | selecta " . a:selecta_args)
  catch /Vim:Interrupt/
    " Swallow the ^C so that the redraw below happens; otherwise there will be
    " leftovers from selecta on the screen
    redraw!
    return
  endtry
  redraw!
  exec a:vim_command . " " . selection
endfunction

" Find all files in all non-dot directories starting in the working directory.
" Fuzzy select one of those. Open the selected file with :e.
nnoremap <leader>f :call SelectaCommand("find * -type f", "", ":e")<cr>

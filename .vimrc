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
colorscheme paramount

fun! s:highlight()
  " highlight Normal ctermbg=235
  highlight Normal ctermbg=NONE
  " highlight CursorLine ctermbg=236
  " highlight MatchParen ctermbg=238

  " For the paramount colorscheme, since otherwise the contrast w/cursorline
  " is insufficient.
  highlight Comment ctermfg=243
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
augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au WinLeave * setlocal nocursorline
augroup END

" }}}

" {{{ Folding
" set foldclose=all " Close folds if you leave them in any way
" set foldcolumn=1 " Show the foldcolumn
" set foldenable " Turn on folding
set foldlevel=3
set foldmethod=syntax " Fold on the syntax
" set foldnestmax=1 " I only like to fold outer functions
" set foldopen=all " Open folds if you touch them in any way
" }}}

" Editing {{{

set hidden
if !has("nvim")
  set noesckeys
endif
set virtualedit=block
set noshowmode
set tags=.git/tags

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

augroup DisableAutoComment
  autocmd BufEnter * setlocal formatoptions-=o
augroup END

" :help ins-completion
function! CleverTab()
  if strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
    return "\<Tab>"

  " https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
  elseif exists('&omnifunc') && &omnifunc != ''
    return "\<C-X>\<C-O>"

  else
    return "\<C-N>"
  endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>

" }}}

" GUI {{{

if has("gui_running")
  " set background=light

  " causes flickering in the terminal for some reason
  set macligatures
end
set guicursor+=a:blinkon0 " disable blinking
set guifont=Source\ Code\ Pro:h13
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

" https://github.com/haya14busa/is.vim/issues/4
map n <Plug>(is-n)zv
map N <Plug>(is-N)zv

" }}}

" Plugins {{{

" netrw

" https://github.com/tpope/vim-vinegar/issues/13
let g:netrw_fastbrowse=0
" let g:netrw_liststyle=0
autocmd FileType netrw setl bufhidden=wipe
let g:netrw_home="~/.vim_tmp"

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

  " https://coreyja.com/vim-spelling-suggestions-fzf/
  function! FzfSpellSink(word)
    exe 'normal! "_ciw'.a:word
  endfunction
  function! FzfSpell()
    let suggestions = spellsuggest(expand("<cword>"))
    return fzf#run({'source': suggestions, 'sink': function("FzfSpellSink"), 'down': 10 })
  endfunction
  nnoremap z= :call FzfSpell()<CR>
endif

" gundo
nnoremap <leader>u :GundoToggle<CR>

" operator-flashy
map y <Plug>(operator-flashy)
nmap Y <Plug>(operator-flashy)$

" vimwiki
let g:vimwiki_global_ext = 0
let g:vimwiki_key_mappings = { 'headers': 0 } " `-` conflicts w/vim-vinegar
let g:vimwiki_list = [{'path': '~/sync/alphanote/', 'syntax': 'markdown', 'ext': '.md'}]
map <leader>wx <Plug>VimwikiToggleListItem

" vim-sleuth

" https://github.com/tpope/vim-sleuth/pull/55
if get(g:, '_has_set_default_indent_settings', 0) == 0
  " Set the indenting level to 2 spaces for the following file types.
  " autocmd FileType typescript,javascript,jsx,tsx,css,html,ruby,elixir,kotlin,vim,plantuml
  "       \ setlocal expandtab tabstop=2 shiftwidth=2
  set expandtab
  set tabstop=2
  set shiftwidth=2
  let g:_has_set_default_indent_settings = 1
endif

" }}}


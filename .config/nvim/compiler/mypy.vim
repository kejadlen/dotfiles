" https://github.com/Konfekt/vim-compilers/blob/master/compiler/mypy.vim
"
" Maintainer: Enno Nagel
" Email:      enno.nagel+vim@gmail.com
"
" This is free and unencumbered software released into the public domain.
"
" Anyone is free to copy, modify, publish, use, compile, sell, or
" distribute this software, either in source code form or as a compiled
" binary, for any purpose, commercial or non-commercial, and by any
" means.

if exists("current_compiler") | finish | endif
let current_compiler = "mypy"

let s:cpo_save = &cpo
set cpo&vim

setlocal makeprg=mypy\ --show-column-numbers
silent CompilerSet makeprg
silent CompilerSet errorformat=%f:%l:%c:\ %t%*[^:]:\ %m

let &cpo = s:cpo_save
unlet s:cpo_save

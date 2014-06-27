setlocal tabstop=4
setlocal softtabstop=4
setlocal shiftwidth=4
setlocal noexpandtab
setlocal commentstring=//\ %s
setlocal foldmethod=syntax
compiler go
let b:dispatch="go test -v"

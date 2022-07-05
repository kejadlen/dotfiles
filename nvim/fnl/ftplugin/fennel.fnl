(set vim.bo.formatprg "fnlfmt /dev/stdin")

; (let [{: nvim_create_autocmd : nvim_command} vim.api]
;   (nvim_create_autocmd :BufWritePre
;                        {:callback #(nvim_command "normal migggqG`i")}))

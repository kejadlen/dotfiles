;; (vim.lsp.set_log_level :debug)

;; default hover windows to have borders
(let [{: handlers : with} vim.lsp
      {: hover} handlers]
  (tset handlers :textDocument/hover (with hover {:border :rounded}))
  (tset handlers :textDocument/signatureHelp (with hover {:border :rounded})))

(let [opts {:noremap true :silent true}]
  (vim.keymap.set :n :<leader>e vim.diagnostic.open_float opts)
  (vim.keymap.set :n "[d" vim.diagnostic.goto_prev opts)
  (vim.keymap.set :n "]d" vim.diagnostic.goto_next opts)
  (vim.keymap.set :n :<leader>q vim.diagnostic.setloclist opts))

(fn on-attach [client bufnr]
  (vim.api.nvim_buf_set_option bufnr :omnifunc "v:lua.vim.lsp.omnifunc")
  (let [bufopts {:noremap true :silent true :buffer bufnr}]
    (vim.keymap.set :n :gD vim.lsp.buf.declaration bufopts)
    (vim.keymap.set :n :gd vim.lsp.buf.definition bufopts)
    (vim.keymap.set :n :K vim.lsp.buf.hover bufopts)
    (vim.keymap.set :n :gi vim.lsp.buf.implementation bufopts)
    (vim.keymap.set :n :<C-k> vim.lsp.buf.signature_help bufopts)
    (vim.keymap.set :n :<leader>wa vim.lsp.buf.add_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wr vim.lsp.buf.remove_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wl
                    (fn []
                      (print (vim.inspect (vim.lsp.buf.list_workspace_folders))))
                    bufopts)
    (vim.keymap.set :n :<leader>D vim.lsp.buf.type_definition bufopts)
    (vim.keymap.set :n :<leader>rn vim.lsp.buf.rename bufopts)
    (vim.keymap.set :n :<leader>ca vim.lsp.buf.code_action bufopts)
    (vim.keymap.set :n :gr vim.lsp.buf.references bufopts)
    (vim.keymap.set :n :<leader>lf vim.lsp.buf.formatting bufopts)))

(let [{: efm : rust_analyzer : tsserver} (require :lspconfig)
      fmt (fn [formatCommand formatStdin]
            {: formatCommand : formatStdin})
      lint (fn [lintCommand lintFormats lintStdin]
             {: lintCommand : lintFormats : lintStdin})
      prettier (fmt "prettier --stdin-filepath ${INPUT}" true)
      ;; https://github.com/alexaandru/nvim-config/blob/master/fnl/config/efm.fnl
      fennelFmt (fmt "fnlfmt /dev/stdin" true)
      fennelLint (lint "fennel --globals vim,hs,spoon --raw-errors $(realpath --relative-to . ${INPUT}) 2>&1"
                       ["%f:%l: %m"] true)
      fennel [fennelFmt fennelLint]]
  ((. efm :setup) {:on_attach on-attach
                   :init_options {:documentFormatting true
                                  :hover true
                                  :documentSymbol true
                                  :codeAction true
                                  :completion true}
                   :settings {:languages {:javascript [prettier]
                                          :typescript [prettier]
                                          :typescriptreact [prettier]
                                          : fennel}}
                   :filetypes [:javascript
                               :typescript
                               :typescriptreact
                               :fennel]})
  ((. rust_analyzer :setup) {:on_attach on-attach
                             :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})
  ((. tsserver :setup) {:on_attach (fn [client bufnr]
                                     (on-attach client bufnr)
                                     (set client.resolved_capabilities.document_formatting
                                          false))}))



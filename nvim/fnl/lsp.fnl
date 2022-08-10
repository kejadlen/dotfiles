(local {: lsp} vim)

(fn fmt [formatCommand formatStdin]
  {: formatCommand : formatStdin})

(fn lint [lintCommand lintFormats lintStdin]
  {: lintCommand : lintFormats : lintStdin})

;; (lsp.set_log_level :debug)

;; default hover windows to have borders
(let [{: hover} lsp.handlers]
  (tset lsp.handlers :textDocument/hover (lsp.with hover {:border :rounded}))
  (tset lsp.handlers :textDocument/signatureHelp
        (lsp.with hover {:border :rounded})))

(let [opts {:noremap true :silent true}]
  (vim.keymap.set :n :<leader>e vim.diagnostic.open_float opts)
  (vim.keymap.set :n "[d" vim.diagnostic.goto_prev opts)
  (vim.keymap.set :n "]d" vim.diagnostic.goto_next opts)
  (vim.keymap.set :n :<leader>q vim.diagnostic.setloclist opts))

(fn on-attach [client bufnr]
  (vim.api.nvim_buf_set_option bufnr :omnifunc "v:lua.lsp.omnifunc")
  (let [bufopts {:noremap true :silent true :buffer bufnr}]
    (vim.keymap.set :n :gD lsp.buf.declaration bufopts)
    (vim.keymap.set :n :gd lsp.buf.definition bufopts)
    (vim.keymap.set :n :K lsp.buf.hover bufopts)
    (vim.keymap.set :n :gi lsp.buf.implementation bufopts)
    (vim.keymap.set :n :<C-k> lsp.buf.signature_help bufopts)
    (vim.keymap.set :n :<leader>wa lsp.buf.add_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wr lsp.buf.remove_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wl
                    (fn []
                      (print (vim.inspect (lsp.buf.list_workspace_folders))))
                    bufopts)
    (vim.keymap.set :n :<leader>D lsp.buf.type_definition bufopts)
    (vim.keymap.set :n :<leader>rn lsp.buf.rename bufopts)
    (vim.keymap.set :n :<leader>ca lsp.buf.code_action bufopts)
    (vim.keymap.set :n :gr lsp.buf.references bufopts)
    (vim.keymap.set :n :<leader>lf lsp.buf.formatting bufopts))
  (when (not= client.name :efm)
    (let [navic (require :nvim-navic)
          {: attach} navic]
      (attach client bufnr))))

(local prettier (fmt "prettier --stdin-filepath ${INPUT}" true))
(local fennel [(fmt "fnlfmt /dev/stdin" true)
               (lint "fennel --globals vim,hs,spoon --raw-errors $(realpath --relative-to . ${INPUT}) 2>&1"
                     ["%f:%l: %m"] true)])

(local efm-setup
       {:on_attach on-attach
        :init_options {:documentFormatting true
                       :hover true
                       :documentSymbol true
                       :codeAction true
                       :completion true}
        :settings {:languages {: fennel
                               :javascript [prettier]
                               :typescript [prettier]
                               :typescriptreact [prettier]}}
        :filetypes [:fennel :javascript :typescript :typescriptreact]})

(local tsserver-attach (fn [client bufnr]
                         (on-attach client bufnr)
                         ;; use prettier for formatting via efm
                         (set client.resolved_capabilities.document_formatting
                              false)))

(let [{: efm : rust_analyzer : tsserver : typeprof} (require :lspconfig)]
  (efm.setup efm-setup)
  (rust_analyzer.setup {:on_attach on-attach
                        :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})
  (tsserver.setup {:on_attach tsserver-attach})
  (typeprof.setup {:on_attach on-attach}))


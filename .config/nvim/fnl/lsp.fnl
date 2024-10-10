;; Per-directory LSP usage:
;;
;; .envrc:
;;   use vim
;;
;; $ rake init:local-nvim[DIR]

(local lspconfig (require :lspconfig))
(local {:api {:nvim_create_autocmd nvim-create-autocmd} : iter : lsp} vim)

; (lsp.set_log_level :debug)

;; rounded borders
(let [{: hover} lsp.handlers]
  (tset lsp.handlers :textDocument/hover (lsp.with hover {:border :rounded}))
  (tset lsp.handlers :textDocument/signatureHelp
        (lsp.with hover {:border :rounded})))

;; set up key mappings
(let [{: keymap} vim
      opts {:noremap true :silent true}
      callback (fn []
                 (keymap.set :n :<leader>e vim.diagnostic.open_float opts)
                 (keymap.set :n :<leader>q vim.diagnostic.setloclist opts)
                 ;; for back-compat - remove once muscle memory has been remapped gd to CTRL+]
                 (keymap.set :n :gd lsp.buf.definition opts)
                 ;; switch out formatting a single line for formatting the whole file instead
                 (keymap.set :n :gqq #(lsp.buf.format {:async true}) opts))]
  (nvim-create-autocmd :LspAttach {: callback}))

;;; basic lsps

(lspconfig.ansiblels.setup {})
(lspconfig.fennel_ls.setup {:settings {:fennel-ls {:extra-globals "hs spoon vim"}}})
(lspconfig.terraformls.setup {})

;;; python

(lspconfig.pyright.setup {:autostart false})
(lspconfig.ruff.setup {:autostart false})
(nvim-create-autocmd :FileType
                     {:pattern :python
                      :callback #(each [_ lsp (ipairs [:pyright :ruff])]
                                   (if (= (vim.fn.executable lsp) 1)
                                       (vim.cmd :LspStart lsp)))})

(let [{: setup} lspconfig.yamlls
      schemas {"https://json.schemastore.org/github-workflow.json" :/.github/workflows/*}]
  (setup {:settings {:yaml {: schemas}}}))

;;; efm-langserver

(let [fmt #{:formatCommand $1 :formatStdin true}
      lint #{:lintCommand $1 :lintFormats $2 :lintStdin true}
      fennel [(fmt "fnlfmt /dev/stdin")
              (lint (-> (iter [:fennel
                               :--globals
                               "vim,hs,spoon"
                               :--raw-errors
                               "$(realpath --relative-to . ${INPUT})"
                               :2>&1])
                        (: :join " ")) ["%f:%l: %m"])]
      js []
      yaml [(fmt "yamlfmt -in")]]
  (lspconfig.efm.setup {:init_options {:documentFormatting true
                                       :hover true
                                       :documentSymbol true
                                       :codeAction true
                                       :completion true}
                        :settings {:languages {: fennel
                                               : js
                                               :typescript js
                                               :typescriptreact js
                                               : yaml}
                                   ;; since otherwise eslint goes haywire
                                   :lintDebounce 1000000000}
                        :filetypes [:fennel :yaml]}))

; (fn on-attach-do [...]
;   (let [fns [...]] ; https://benaiah.me/posts/everything-you-didnt-want-to-know-about-lua-multivals/
;     (fn [client bufnr]
;       (on-attach client bufnr)
;       (each [_ f (ipairs fns)]
;         (f client bufnr)))))
;
; (fn attach-navic [client bufnr]
;   ((. (require :nvim-navic) :attach) client bufnr))
;
; (fn enable-fmt [client bufnr]
;   (let [bufopts {:noremap true :silent true :buffer bufnr}]
;     (vim.keymap.set :n :<leader>lf #(lsp.buf.format {:async true}) bufopts)))
;
; (fn disable-rename [client]
;   (set client.server_capabilities.rename false))
;
; (fn setup-lsp [lsp config]
;   (let [{: setup} (. lspconfig lsp)]
;     (setup (or config {:on_attach on-attach}))))
;
; (local eslint
;        {:lintCommand "eslint -f visualstudio --stdin --stdin-filename ${INPUT}"
;         :lintIgnoreExitCode true
;         :lintStdin true
;         :lintFormats ["%f(%l,%c): %tarning %m" "%f(%l,%c): %rror %m"]})
;
; (local eslintd-fmt
;        (fmt "eslint_d --stdin --fix-to-stdout --stdin-filename=${INPUT}"))

; (setup-lsp :ruby_lsp)
;
; (setup-lsp :rust_analyzer
;            {:on_attach on-attach
;             :cmd [:rustup :run :stable :rust-analyzer]
;             :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})
;
; (setup-lsp :ts_ls {:on_attach (on-attach-do attach-navic)})
; (setup-lsp :vuels {:on_attach (on-attach-do attach-navic)})

;; TODO
;; https://github.com/Shopify/ruby-lsp/issues/188#issuecomment-1268932965
; (local request-diagnostics
;        (fn [client buffer]
;          (let [{: util : diagnostic} lsp
;                params (util.make_text_document_params buffer)
;                publish-diagnostics #(diagnostic.on_publish_diagnostics nil
;                                                                        (vim.tbl_extend :keep
;                                                                                        params
;                                                                                        {:diagnostics $1.items})
;                                                                        {:client_id client.id})
;                update-diagnostics #(when (not $1)
;                                      (publish-diagnostics $2))
;                callback #(client.request :textDocument/diagnostic
;                                          {:textDocument params}
;                                          update-diagnostics)]
;            (vim.api.nvim_create_autocmd [:BufEnter :BufWritePre :CursorHold]
;                                         {: buffer : callback}))))

; (fn setup-ruby-ls []
;   (let []
;     (setup-lsp :ruby_ls {:on_attach (on-attach-do request-diagnostics)})))

; {: setup-lsp}

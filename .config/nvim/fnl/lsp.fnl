;; Per-directory LSP usage:
;;
;; .envrc:
;;   use vim
;;
;; $ rake init:local-nvim

(local lspconfig (require :lspconfig))
(local {: lsp} vim)

; (lsp.set_log_level :debug)

;; Use rounded borders for :LspInfo
(let [{: default_options} (require :lspconfig.ui.windows)]
  (tset default_options :border :rounded))

;;; fennel-ls

(let [configs (require :lspconfig.configs)]
  (tset configs :fennel-ls
        {:default_config {:cmd [:/opt/homebrew/bin/fennel-ls]
                          :filetypes [:fennel]
                          :root_dir #(lspconfig.util.find_git_ancestor $1)
                          :settings {}}})
  (tset configs :steep {:default_config {:cmd ["steep langserver"]
                                         :filetypes [:ruby]
                                         :root_dir #(lspconfig.util.find_git_ancestor $1)
                                         :settings {}}}))

(let [{: fennel-ls} lspconfig]
  (fennel-ls.setup (vim.lsp.protocol.make_client_capabilities)))

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
  (vim.api.nvim_buf_set_option bufnr :omnifunc "v:lua.vim.lsp.omnifunc")
  (let [bufopts {:noremap true :silent true :buffer bufnr}]
    (vim.keymap.set :n :gD lsp.buf.declaration bufopts)
    (vim.keymap.set :n :gd lsp.buf.definition bufopts)
    (vim.keymap.set :n :K lsp.buf.hover bufopts)
    (vim.keymap.set :n :gi lsp.buf.implementation bufopts)
    (vim.keymap.set :n :<C-k> lsp.buf.signature_help bufopts)
    (vim.keymap.set :n :<leader>wa lsp.buf.add_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wr lsp.buf.remove_workspace_folder bufopts)
    (vim.keymap.set :n :<leader>wl
                    #(print (vim.inspect (lsp.buf.list_workspace_folders)))
                    bufopts)
    (vim.keymap.set :n :<leader>D lsp.buf.type_definition bufopts)
    (vim.keymap.set :n :<leader>rn lsp.buf.rename bufopts)
    (vim.keymap.set :n :<leader>ca lsp.buf.code_action bufopts)
    (vim.keymap.set :n :gr lsp.buf.references bufopts)
    (vim.keymap.set :n :<leader>lf #(lsp.buf.format {:async true}) bufopts)))

(fn on-attach-do [...]
  (let [fns [...]] ; https://benaiah.me/posts/everything-you-didnt-want-to-know-about-lua-multivals/
    (fn [client bufnr]
      (on-attach client bufnr)
      (each [_ f (ipairs fns)]
        (f client bufnr)))))

(fn attach-navic [client bufnr]
  ((. (require :nvim-navic) :attach) client bufnr))

(fn disable-fmt [client]
  (set client.resolved_capabilities.document_formatting false))

(fn setup-lsp [lsp config]
  (let [{: setup} (. lspconfig lsp)]
    (setup (or config {:on_attach on-attach}))))

(local fmt #{:formatCommand $1 :formatStdin true})
(local lint #{:lintCommand $1 :lintFormats $2 :lintStdin true})
(local fennel-lint
       "fennel --globals vim,hs,spoon --raw-errors $(realpath --relative-to . ${INPUT}) 2>&1")

(local fennel [(fmt "fnlfmt /dev/stdin") (lint fennel-lint ["%f:%l: %m"])])
(local eslint
       {:lintCommand "eslint -f visualstudio --stdin --stdin-filename ${INPUT}"
        :lintIgnoreExitCode true
        :lintStdin true
        :lintFormats ["%f(%l,%c): %tarning %m" "%f(%l,%c): %rror %m"]})

(local prettier (fmt "prettier --stdin-filepath ${INPUT}"))
(local javascript [eslint prettier])
(local black (fmt "black --quiet -"))
(local flake8 (lint "flake8 --stdin-display-name ${INPUT} -" ["%f:%l:%c: %m"]))
(local isort (fmt "isort --quiet --profile black -"))
(local python [black isort])

(setup-lsp :efm {:on_attach on-attach
                 :init_options {:documentFormatting true
                                :hover true
                                :documentSymbol true
                                :codeAction true
                                :completion true}
                 :settings {:languages {: fennel
                                        : javascript
                                        : python
                                        :typescript javascript
                                        :typescriptreact javascript
                                        :vue [prettier]}}
                 :filetypes [:fennel
                             :javascript
                             :typescript
                             :python
                             :typescriptreact
                             :vue]})

(setup-lsp :ansiblels)
(setup-lsp :elmls)
(setup-lsp :fennel-ls)
(setup-lsp :pylsp {:on_attach (on-attach-do attach-navic disable-fmt)})
(setup-lsp :pyright
           {:on_attach on-attach
            :settings {:python {:analysis {:autoImportCompletions true}}}})

(setup-lsp :rust_analyzer
           {:on_attach on-attach
            :cmd [:rustup :run :stable :rust-analyzer]
            :settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})

(setup-lsp :terraformls)

; (setup-lsp :tsserver {:on_attach (on-attach-do attach-navic disable-fmt)})
(setup-lsp :vuels {:on_attach (on-attach-do attach-navic disable-fmt)})

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

{: setup-lsp}


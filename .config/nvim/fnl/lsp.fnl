(local {:api {:nvim_create_autocmd nvim-create-autocmd} : keymap : lsp} vim)

; (lsp.set_log_level :debug)

;; set up key mappings
(let [opts {:noremap true :silent true}
      callback (fn []
                 (keymap.set :n :<leader>e vim.diagnostic.open_float opts)
                 (keymap.set :n :<leader>q vim.diagnostic.setloclist opts)
                 ;; switch out formatting a single line for formatting the whole file instead
                 (keymap.set :n :gqq #(lsp.buf.format {:async true}) opts))]
  (nvim-create-autocmd :LspAttach {: callback}))

;; TODO figure out which should be globally enabled
(lsp.enable :ansiblels)
(lsp.enable :efm)
(lsp.enable :fennel_ls)
(lsp.enable :pyright)
(lsp.enable :ruby_lsp)
(lsp.enable :ruff)
(lsp.enable :rust_analyzer)
(lsp.enable :sorbet)
(lsp.enable :terraformls)
(lsp.enable :ts_ls)

;;; configs

(let [schemas {"https://json.schemastore.org/github-workflow.json" :/.github/workflows/*}]
  (lsp.config :yamlls {:settings {:yaml {: schemas}}}))

;; efm-langserver
(let [fmt #{:formatCommand $1 :formatStdin true}
      lint #{:lintCommand $1 :lintFormats $2 :lintStdin true}
      fennel [(fmt "fnlfmt /dev/stdin")
              (lint (table.concat [:fennel
                                   "--globals vim,hs,spoon"
                                   :--raw-errors
                                   "$(realpath --relative-to . ${INPUT})"
                                   :2>&1] " ")
                    ["%f:%l: %m"])]
      js [{:formatCommand (table.concat ["prettier --stdin --stdin-filepath ${INPUT}"
                                         "${--range-start:charStart} ${--range-end:charEnd}"
                                         "${--tab-width:tabWidth} ${--use-tabs:!insertSpaces}"]
                                        " ")
           :formatStdin true
           :formatCanRange true
           :rootMarkers [:.prettierrc.json]}]
      json [(fmt "jq .")]
      yaml [(fmt "yamlfmt -in")]]
  (lsp.config :efm
              {:init_options {:documentFormatting true
                              :hover true
                              :documentSymbol true
                              :codeAction true
                              :completion true}
               :settings {:languages {: fennel
                                      : js
                                      : json
                                      :typescript js
                                      :typescriptreact js
                                      : yaml}
                          ;; since otherwise eslint goes haywire
                          :lintDebounce 1000000000}
               :filetypes [:fennel :json :typescriptreact :yaml]}))

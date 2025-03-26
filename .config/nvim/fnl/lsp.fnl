;; Per-directory LSP usage:
;;
;; .envrc:
;;   use vim
;;
;; $ rake init:local-nvim[DIR]

(local lspconfig (require :lspconfig))
(local {:api {:nvim_create_autocmd nvim-create-autocmd} : iter : lsp} vim)

; (lsp.set_log_level :debug)

;; set up key mappings
(let [{: keymap} vim
      opts {:noremap true :silent true}
      callback (fn []
                 (keymap.set :n :<leader>e vim.diagnostic.open_float opts)
                 (keymap.set :n :<leader>q vim.diagnostic.setloclist opts)
                 ;; switch out formatting a single line for formatting the whole file instead
                 (keymap.set :n :gqq #(lsp.buf.format {:async true}) opts))]
  (nvim-create-autocmd :LspAttach {: callback}))

;;; basic lsps

(lspconfig.ansiblels.setup {})
(lspconfig.fennel_ls.setup {})
(lspconfig.ruby_lsp.setup {})
(lspconfig.rust_analyzer.setup {})
(lspconfig.terraformls.setup {})
(lspconfig.ts_ls.setup {})

(let [{: setup} lspconfig.yamlls
      schemas {"https://json.schemastore.org/github-workflow.json" :/.github/workflows/*}]
  (setup {:settings {:yaml {: schemas}}}))

;;; python

;; only enable pyright/ruff if they're there
(lspconfig.pyright.setup {:autostart false})
(lspconfig.ruff.setup {:autostart false})
(nvim-create-autocmd :FileType
                     {:pattern :python
                      :callback #(each [_ lsp (ipairs [:pyright :ruff])]
                                   (if (= (vim.fn.executable lsp) 1)
                                       (vim.cmd :LspStart lsp)))})

;;; efm-langserver

(let [fmt #{:formatCommand $1 :formatStdin true}
      lint #{:lintCommand $1 :lintFormats $2 :lintStdin true}
      fennel [(fmt "fnlfmt /dev/stdin")
              (lint (: (iter [:fennel
                              "--globals vim,hs,spoon"
                              :--raw-errors
                              "$(realpath --relative-to . ${INPUT})"
                              :2>&1]) :join " ")
                    ["%f:%l: %m"])]
      js [{:formatCommand (let [x (iter ["prettier --stdin --stdin-filepath ${INPUT}"
                                         "${--range-start:charStart} ${--range-end:charEnd}"
                                         "${--tab-width:tabWidth} ${--use-tabs:!insertSpaces}"])]
                            (x:join " "))
           :formatStdin true
           :formatCanRange true
           :rootMarkers [:.prettierrc.json]}]
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
                        :filetypes [:fennel :typescriptreact :yaml]}))

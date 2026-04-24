(local {:api {:nvim_buf_set_mark nvim-buf-set-mark
              :nvim_create_autocmd nvim-create-autocmd
              :nvim_get_current_buf nvim-get-current-buf}
        : keymap
        : treesitter} vim)

;;; parsers
;; Async install at startup; subsequent calls no-op for already-installed parsers.
(let [ts (require :nvim-treesitter)]
  (ts.install [:fennel :hcl :lua :python :query :ruby :rust :terraform
               :typescript :yaml]))

;;; highlighting
;; Native treesitter highlight per filetype with a parser; pcall covers filetypes without one.
(nvim-create-autocmd :FileType
                     {:callback #(pcall treesitter.start $1.buf)})

;;; custom queries
(treesitter.language.register :yaml :yaml.ansible)
(treesitter.query.set :python :folds "[
  (function_definition)
  (class_definition)
  (block)
] @fold
[
  (import_statement)
  (import_from_statement)
]+ @fold")

;;; incremental selection
;; Replaces the `incremental_selection` module from nvim-treesitter master.
;; Maintains a per-buffer stack of nodes; each expansion pushes the parent.
(let [stacks {}
      get-stack #(or (. stacks $1) [])
      select-node (fn [node]
                    (let [(srow scol erow ecol) (node:range)]
                      (nvim-buf-set-mark 0 :< (+ srow 1) scol {})
                      (nvim-buf-set-mark 0 :> (+ erow 1)
                                         (math.max (- ecol 1) 0) {})
                      (vim.cmd "normal! gv")))
      push (fn [bufnr node]
             (let [stack (get-stack bufnr)]
               (table.insert stack node)
               (tset stacks bufnr stack)
               (select-node node)))
      expand (fn []
               (let [bufnr (nvim-get-current-buf)
                     stack (get-stack bufnr)
                     current (. stack (length stack))
                     parent (and current (current:parent))]
                 (when parent (push bufnr parent))))
      shrink (fn []
               (let [bufnr (nvim-get-current-buf)
                     stack (get-stack bufnr)]
                 (when (> (length stack) 1)
                   (table.remove stack)
                   (tset stacks bufnr stack)
                   (select-node (. stack (length stack))))))]
  (keymap.set :n :gnn
              #(let [bufnr (nvim-get-current-buf)
                     node (treesitter.get_node)]
                 (when node
                   (tset stacks bufnr [])
                   (push bufnr node))))
  (keymap.set :x :grn expand)
  (keymap.set :x :grc expand)
  (keymap.set :x :grm shrink))

;;; textobjects (nvim-treesitter-textobjects main branch)
(let [{: setup} (require :nvim-treesitter-textobjects)
      ts-select (require :nvim-treesitter-textobjects.select)
      ts-swap (require :nvim-treesitter-textobjects.swap)
      ts-move (require :nvim-treesitter-textobjects.move)
      bind-each (fn [modes specs action]
                  (each [_ [lhs query] (ipairs specs)]
                    (keymap.set modes lhs #(action query :textobjects))))]
  (setup {:select {:lookahead true} :move {:set_jumps true}})

  (bind-each [:x :o]
             [[:af "@function.outer"]
              [:if "@function.inner"]
              [:ac "@class.outer"]
              [:ic "@class.inner"]
              [:ab "@block.outer"]
              [:ib "@block.inner"]
              [:aa "@parameter.outer"]
              [:ia "@parameter.inner"]]
             ts-select.select_textobject)

  (keymap.set :n :<leader>a #(ts-swap.swap_next "@parameter.inner"))
  (keymap.set :n :<leader>A #(ts-swap.swap_previous "@parameter.inner"))

  (bind-each [:n :x :o]
             [["]a" "@parameter.inner"]
              ["]b" "@block.outer"]
              ["]c" "@class.inner"]
              ["]f" "@function.outer"]]
             ts-move.goto_next_start)
  (bind-each [:n :x :o]
             [["]A" "@parameter.inner"]
              ["]B" "@block.outer"]
              ["]C" "@class.outer"]
              ["]F" "@function.outer"]]
             ts-move.goto_next_end)
  (bind-each [:n :x :o]
             [["[a" "@parameter.inner"]
              ["[b" "@block.outer"]
              ["[c" "@class.outer"]
              ["[f" "@function.outer"]]
             ts-move.goto_previous_start)
  (bind-each [:n :x :o]
             [["[A" "@parameter.inner"]
              ["[B" "@block.outer"]
              ["[C" "@class.outer"]
              ["[F" "@function.outer"]]
             ts-move.goto_previous_end))

;;; treesitter-context
(let [{: setup} (require :treesitter-context)]
  (setup))

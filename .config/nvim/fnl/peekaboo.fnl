(local {: floor} math)
(local {: columns : lines} vim.o)
(local {:nvim_create_buf nvim-create-buf :nvim_open_win nvim-open-win} vim.api)

;; https://github.com/junegunn/vim-peekaboo/issues/68/#issuecomment-1013782594
(fn []
  (let [width (floor (* columns 0.8))
        height (floor (* lines 0.8))
        row (- (/ (- lines height) 2) 1)
        col (/ (- columns width) 2)
        opts {:relative :editor
              : row
              : col
              : width
              : height
              :style :minimal
              :border :rounded}
        buf (nvim-create-buf false true)]
    (nvim-open-win buf true opts)))

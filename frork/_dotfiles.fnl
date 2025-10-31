(local {: ok :utils {: dirname}} (require :flork))

(ok :git "~/.dotfiles" "https://git.kejadlen.dev/alpha/dotfiles.git")

(let [dotfiles [:.config
                :.digrc
                :.gemrc
                :.gitconfig
                :.git_templates
                :.hammerspoon
                :.inputrc
                :.p10k.zsh
                :.profile
                :.ruby-version
                :.zsh
                :.zshenv
                :.zshrc
                :.bundle/config
                :.cargo/config.toml]]
  (each [_ v (ipairs dotfiles)]
    (let [src (.. :$HOME/.dotfiles/ v)
          dest (.. :$HOME/ v)]
      ;; TODO fix this - it doesn't work
      (when (v:match "/")
        (-?> dest dirname (partial #(ok :directory))))
      (ok :symlink dest src))))

;; for per-system configuration
(ok :directory :$HOME/.config/jj/conf.d)

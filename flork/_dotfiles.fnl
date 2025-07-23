(local {: ok :utils {: dirname : expand-env-vars}} (require :flork))

(let [dotfiles [:.config
                :.digrc
                :.gemrc
                :.gitconfig
                :.hammerspoon
                :.inputrc
                :.local
                :.p10k.zsh
                :.profile
                :.ruby-version
                :.tmux.conf
                :.zsh
                :.zshenv
                :.zshrc
                :.bundle/config
                :.cargo/config.toml
                :.docker/config.json]]
  (each [_ v (ipairs dotfiles)]
    (let [src (expand-env-vars (.. :$HOME/.dotfiles/ v))
          dest (expand-env-vars (.. :$HOME/ v))]
      (if (v:match "/") (ok :directory (dirname dest)))
      (ok :symlink dest src))))

(ok :directory (expand-env-vars :$HOME/.config/jj/conf.d))

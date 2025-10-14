(local {: ok :utils {: dirname : expand-env-vars}} (require :flork))

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
    (let [src (expand-env-vars (.. :$HOME/.dotfiles/ v))
          dest (expand-env-vars (.. :$HOME/ v))]
      (if (v:match "/") (ok :directory (dirname dest)))
      (ok :symlink dest src))))

(ok :directory (expand-env-vars :$HOME/.config/jj/conf.d))

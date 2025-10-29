(local {: ok :utils {: dirname}} (require :flork))

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
      (when (v:match "/")
        (-?> dest dirname (partial #(ok :directory))))
      (ok :symlink dest src))))

(ok :directory :$HOME/.config/jj/conf.d)

(ok :symlink :$HOME/CLAUDE.md :$HOME/.dotfiles/ai/CLAUDE.md)

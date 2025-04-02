(local {: ok :utils {: chomp : dirname : expand-env-vars : sh*}}
       (require :flork))

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

(let [jj-config (chomp (sh* :jj :config :path :--user))]
  (ok :directory (dirname jj-config))
  (ok :symlink jj-config (expand-env-vars :$HOME/.config/jj/config.toml)))


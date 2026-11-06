(local {: ok :utils {: dirname}} (require :frork))

(ok :git "~/.dotfiles" "https://git.kejadlen.dev/alpha/dotfiles.git")

(let [dotfiles [:.config
                :.digrc
                :.gemrc
                :.git_templates
                :.hammerspoon
                :.inputrc
                :.p10k.zsh
                :.profile
                :.ruby-version
                :.ssh
                :.zsh
                :.zshenv
                :.zshrc
                :.bundle/config
                :.cargo/config.toml]]
  (each [_ v (ipairs dotfiles)]
    (let [src (.. :$HOME/.dotfiles/ v)
          dest (.. :$HOME/ v)]
      (when (v:match "/")
        (ok :directory (dirname dest)))
      (ok :symlink dest src))))

(ok :symlink "~/.claude" "~/.dotfiles/ai/claude")

(ok :directory "~/.pi")
(ok :symlink "~/.pi/agent" "~/.dotfiles/ai/pi")

;; for per-system configuration
(ok :directory :$HOME/.config/jj/conf.d)

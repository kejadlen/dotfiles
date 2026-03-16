(local {: ok : no :utils {: dirname}} (require :flork))

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
      ;; TODO fix this - it doesn't work
      (when (v:match "/")
        (-?> dest dirname (partial #(ok :directory))))
      (ok :symlink dest src))))

(ok :symlink "~/.dotfiles/ai/claude" "~/.claude")
(ok :symlink "~/.dotfiles/ai/_AGENTS.md" "~/.claude/CLAUDE.md")

(ok :directory "~/.pi")
(ok :symlink "~/.dotfiles/ai/pi" "~/.pi/agent")

;; moved to .config/git/config
(no :symlink :$HOME/.gitconfig :$HOME/.dotfiles/.gitconfig)

;; for per-system configuration
(ok :directory :$HOME/.config/jj/conf.d)

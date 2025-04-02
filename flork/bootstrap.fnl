;; TODO Figure out how I want to bootstrap this from a blank slate

(local {: ok
        :utils {: assert-bin : assert-platform : chomp : expand-env-vars : sh*}}
       (require :flork))

(ok :directory (expand-env-vars :$HOME/src))

(ok :git (expand-env-vars :$HOME/.dotfiles)
    "https://git.kejadlen.dev/alpha/dotfiles.git")

(require :_dotfiles)

(if (pcall assert-platform :Darwin) (require :_macos))

(ok :brew)
;; this is slow...
; (ok :brew-bundle (expand-env-vars :$HOME/.dotfiles/Brewfile))

;; TODO figure out when this actually needs to be run (or maybe run it always?)
; (utils.sh* :bat :cache :--build)

;; https://tratt.net/laurie/blog/2024/faster_shell_startup_with_shell_switching.html
(do
  (assert-bin :dscl) ; TODO Linux
  (let [desired-shell :/bin/sh
        out (sh* :dscl "." :-read (expand-env-vars :$HOME/) :UserShell)
        actual-shell (chomp (out:match "UserShell: (.+)"))]
    (if (not= actual-shell desired-shell) (sh* :chsh :-s desired-shell))))

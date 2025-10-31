(local {: ok :utils {: assert-bin : chomp : expand-path : platform : sh!}}
       (require :frork))

(require :types)

;; some basics
(ok :directory "~/src")

;; dotfiles
(require :_dotfiles)

(if (= platform :darwin) (require :_macos))

;; https://tratt.net/laurie/blog/2024/faster_shell_startup_with_shell_switching.html
(do
  (assert-bin :dscl) ; TODO Linux
  (let [desired-shell :/bin/sh
        out (sh! :dscl "." :-read (expand-path :$HOME/) :UserShell)
        actual-shell (chomp (out:match "UserShell: (.+)"))]
    (if (not= actual-shell desired-shell) (sh! :chsh :-s desired-shell))))

;; TODO figure out when these should be run - surely not necessary every single time
(sh! :bat :cache :--build)
(sh! :brew :services :restart :felixkratz/formulae/sketchybar)

;; TODO
;; - install neovim plugins
;; - install tmux plugins
;; - install numderline

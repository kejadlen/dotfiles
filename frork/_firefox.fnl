;; manual steps:
;;  1. Enable toolkit.legacyUserProfileCustomizations.stylesheets in about:config

(local {: view} (require :fennel))
(local lfs (require :lfs))
(local {: ok :utils {: assert-platform : expand-env-vars}} (require :flork))

(assert-platform :Darwin)

(let [profiles-dir (expand-env-vars "$HOME/Library/Application Support/Firefox/Profiles")
      (iter dir-obj) (lfs.dir profiles-dir)
      default-dirs (icollect [entry #(iter dir-obj)]
                     (if (entry:match :.default$) entry))
      src (expand-env-vars :$HOME/.dotfiles/firefox/chrome)]
  (each [_ dir (ipairs default-dirs)]
    (ok :symlink (table.concat [profiles-dir dir :chrome] "/") src)))

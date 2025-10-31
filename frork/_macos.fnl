(local {: ok : register :utils {: assert-bin : dirname : expand-path : sh!}}
       (require :frork))

(ok :brew)

(require :_defaults)

(let [src "~/.dotfiles/macos/DefaultKeyBinding.dict"
      dest "~/Library/KeyBindings/DefaultKeyBinding.dict"]
  (ok :directory "~/Library/KeyBindings")
  (ok :symlink dest src))

(let [mailmate-keybindings "~/Library/Application Support/MailMate/Resources/KeyBindings/Alpha.plist"]
  (ok :directory (dirname mailmate-keybindings))
  (ok :symlink mailmate-keybindings "~/.dotfiles/macos/MailMate.plist"))

;; this is slow - maybe replace with a hand-rolled assertion type?
(ok :brew-bundle "~/.dotfiles/Brewfile")

(register :dock {:status (fn []
                           ;; TODO install instead of asserting
                           (assert-bin :dockutil)
                           (let [out (sh! :dockutil :--list)
                                 items (icollect [line (out:gmatch "[^\n]+")]
                                         ;; ignore recent apps
                                         (if (not (line:match "%srecentApps%s"))
                                             (line:match "%S+")))]
                             (case items
                               [:Downloads] :ok
                               _ :conflict-upgrade)))
                 :install #(error "dock install not supported")
                 :upgrade (fn []
                            (sh! :dockutil :--remove :all)
                            (sh! :dockutil :--add (expand-path "~/Downloads")
                                 :--view :auto :--display :stack :--sort
                                 :datemodified)
                            ;; TODO if we add handlers, do this there instead
                            (sh! :killall :Dock))})
(ok :dock)

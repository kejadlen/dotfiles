(local {: ok : register :utils {: assert-bin : dirname : expand-path : sh!}}
       (require :frork))

(ok :brew)

(require :_defaults)

(let [src "~/.dotfiles/macos/DefaultKeyBinding.dict"
      dest "~/Library/KeyBindings/DefaultKeyBinding.dict"]
  (ok :directory "~/Library/KeyBindings")
  (ok :symlink dest src))

(let [mailmate "~/Library/Application Support/MailMate/"
      resources (.. mailmate :Resources/)]
  (ok :directory (dirname resources))
  (ok :symlink (.. resources :KeyBindings/Alpha.plist)
      "~/.dotfiles/macos/MailMate/KeyBindings.plist")
  (ok :symlink (.. mailmate :Tags.plist)
      "~/.dotfiles/macos/MailMate/Tags.plist"))

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

;; Hammerspoon uses Lua 5.4, but brew's lua formula tracks the latest
;; version. Configure luarocks to find lua@5.4 and install fennel there
;; so Hammerspoon can require it.
(sh! :luarocks :--lua-version=5.4 :--local :config :variables.LUA
     :/opt/homebrew/opt/lua@5.4/bin/lua)
(sh! :luarocks :--lua-version=5.4 :--local :config :variables.LUA_DIR
     :/opt/homebrew/opt/lua@5.4)
(sh! :luarocks :--lua-version=5.4 :--local :install :fennel)

;; TODO
;; - install numderline fonts

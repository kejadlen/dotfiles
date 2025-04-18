(local {: ok :utils {: assert-bin : dirname : expand-env-vars : sh*}}
       (require :flork))

(local lfs (require :lfs))

(require :_defaults)

(let [src (expand-env-vars :$HOME/.dotfiles/macos/DefaultKeyBinding.dict)
      dest (expand-env-vars :$HOME/Library/KeyBindings/DefaultKeyBinding.dict)]
  (ok :directory (expand-env-vars :$HOME/Library/KeyBindings))
  (ok :symlink dest src))

(let [src (expand-env-vars :$HOME/.dotfiles/macos/colors)
      dest (expand-env-vars :$HOME/Library/Colors)
      (iter dir-obj) (lfs.dir src)
      colors (icollect [entry #(iter dir-obj)]
               (if (entry:match "%.clr$") entry))]
  (ok :directory dest)
  (each [_ color (ipairs colors)]
    (ok :symlink (.. dest "/" color) (.. src "/" color))))

;; TODO tridactyl: https://librewolf.net/docs/faq/#how-can-i-get-tridactyls-native-messaging-to-work-when-i-install-librewolf-with-flatpak
(let [src (expand-env-vars "$HOME/Library/Application Support/Mozilla/NativeMessagingHosts")
      dest (src:gsub :Mozilla :LibreWolf)]
  (ok :symlink dest src))

(let [mailmate-keybindings (expand-env-vars "$HOME/Library/Application Support/MailMate/Resources/KeyBindings/Alpha.plist")]
  (ok :directory (dirname mailmate-keybindings))
  (ok :symlink mailmate-keybindings
      (expand-env-vars :$HOME/.dotfiles/macos/MailMate.plist)))

(assert-bin :dockutil)
(let [out (sh* :dockutil :--list)
      items (icollect [line (out:gmatch "[^\n]+")]
              ;; ignore recent apps
              (if (not (line:match "%srecentApps%s")) (line:match "%S+")))]
  (case items
    (where [item] (not= item :Downloads)) (do
                                            (sh* :dockutil :--remove :all)
                                            (sh* :dockutil :--add
                                                 (expand-env-vars :$HOME/Downloads)
                                                 :--view :auto :--display :stack
                                                 :--sort :datemodified)
                                            (sh* :killall :Dock))
    _ (print "ok: dockutil")))

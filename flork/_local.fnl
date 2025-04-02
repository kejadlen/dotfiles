(local {: ok :utils {: expand-env-vars}} (require :flork))

(let [ComputerName "Perfect Cherry Blossom"
      LocalHostName (ComputerName:gsub " " "-")]
  (each [pref val (pairs {: ComputerName : LocalHostName})]
    (ok :scutil pref val)))

; (ok :brew-bundle (expand-env-vars :$HOME/.dotfiles/Brewfile.personal))

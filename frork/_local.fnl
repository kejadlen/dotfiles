(local {: ok} (require :flork))

(let [ComputerName "Perfect Cherry Blossom"
      LocalHostName (ComputerName:gsub " " "-")]
  (each [pref val (pairs {: ComputerName : LocalHostName})]
    (ok :scutil pref val)))

(ok :brew-bundle "~/.dotfiles/Brewfile.personal")

;; Links are a map of ~/<dest> to ~/.dotfiles/<src>, so another entry point
;; (like a work machine's overlay repo) can reshape them before applying.
(local {: ok :utils {: dirname}} (require :frork))

(local links (doto (collect [_ path (ipairs [:.config
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
                                             :.cargo/config.toml])]
                     path
                     path)
               (tset :.claude :ai/claude)
               (tset :.pi/agent :ai/pi)))

(fn apply [?links]
  (let [links (or ?links links)
        dests (icollect [dest (pairs links)] dest)
        dirs {}]
    (table.sort dests) ; so the output is always in the same order
    (each [_ dest (ipairs dests)]
      (let [path (.. :$HOME/ dest)
            dir (dirname path)]
        (when (and (dest:match "/") (not (. dirs dir)))
          (tset dirs dir true)
          (ok :directory dir))
        (ok :symlink path (.. :$HOME/.dotfiles/ (. links dest)))))))

{: links : apply}

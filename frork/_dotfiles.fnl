;; Links are a map of ~/<dest> to ~/.dotfiles/<src>, so another entry point
;; (like a work machine's overlay repo) can reshape them before applying.
(local {: ok :utils {: dirname}} (require :frork))
(require :types)

(local links (collect [_ path (ipairs [:.config
                                       :.digrc
                                       :.gemrc
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
               path))

;; 1Password's agent config has no include, so a machine swaps the whole file
;; by dropping this link and pointing agent.toml somewhere else.
(tset links :.config/1Password/ssh/agent.toml
      :.config/1Password/ssh/agent.default.toml)

;; Agents keep their state beside their config, so only the tracked entries
;; link in and the rest stays a real directory outside the repo.
(each [dest [src names] (pairs {:.claude [:ai/claude
                                          [:CLAUDE.md
                                           :hooks
                                           :output-styles
                                           :rules
                                           :settings.json
                                           :skills
                                           :statusline.sh]]
                                :.pi/agent [:ai/pi
                                            [:AGENTS.md
                                             :extensions
                                             :git
                                             :keybindings.json
                                             :models.json
                                             :settings.json]]})]
  (each [_ name (ipairs names)]
    (tset links (.. dest "/" name) (.. src "/" name))))

;; Paths earlier versions of these links created, cleared on every machine.
(local retired [:.git_templates])

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
        (ok :symlink path (.. :$HOME/.dotfiles/ (. links dest)))))
    (each [_ dest (ipairs retired)]
      (ok :absent (.. :$HOME/ dest)))))

{: links : apply}

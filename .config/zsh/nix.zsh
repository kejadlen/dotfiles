# /etc/zshrc is skipped because ~/.zshenv sets `no_global_rcs` (z4h),
# so source the nix-daemon hook here instead.
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# available in 2.1
# eval "$(devenv hook zsh)"

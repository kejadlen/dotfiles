{ config, pkgs, ... }:

let
  dotfiles = fetchGit {
    url = "https://github.com/kejadlen/dotfiles.git";
    ref = "main";
    rev = "b7c7b0bee54758917dbd699b556868220869ad17";
    submodules = true;
  };
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "alpha";
  home.homeDirectory = "/Users/alpha";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion = "21.05";

  # https://github.com/nix-community/home-manager/pull/2647
  home.stateVersion = "20.09";

  home.file = {
    ".dotfiles".source = dotfiles;
    # ".vim".source = ../../.vim;
    # ".vimrc".source = ../../.vimrc;

    # Hacky way of creating directories
    ".config/op/.keep".text = "";
    ".vim_tmp/.keep".text = "";
    ".vim_undo/.keep".text = "";
  };

  home.packages = with pkgs; [
    ansible
    # macvim
    tmux
    vim
  ];
}

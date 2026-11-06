{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Its own nixpkgs, since a different tree-sitter breaks its vendored-deps hash.
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    { nixpkgs, neovim-nightly-overlay, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      # Tools with a DotSlash file in bin/ stay there.
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          profile = pkgs.buildEnv {
            name = "profile";
            paths = with pkgs; [
              # nix-direnv needs bash 4 or later.
              bash
              dotslash
              entr
              eza
              git
              neovim-nightly-overlay.packages.${system}.default
              nix-direnv
              sqlite
              tmux
              zsh
            ];
          };
        }
      );
    };
}

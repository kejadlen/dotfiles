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
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "claude-code"
                "discord"
                "slack"
                "whatsapp-for-mac"
                "zoom"
              ];
          };
        in
        {
          profile = pkgs.buildEnv {
            name = "profile";
            paths =
              with pkgs;
              [
                # nix-direnv needs bash 4 or later.
                bash
                claude-code
                dotslash
                entr
                eza
                git
                neovim-nightly-overlay.packages.${system}.default
                nix-direnv
                pi-coding-agent
                sqlite
                tmux
                zsh
              ]
              ++ lib.optionals stdenv.hostPlatform.isDarwin [
                discord
                omniwm
                signal-desktop
                slack
                telegram-desktop
                whatsapp-for-mac
                zoom-us
              ];
          };
        }
      );

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShellNoCC {
          packages = [ nixpkgs.legacyPackages.${system}.ruby_4_0 ];
        };
      });
    };
}

{
  description = "Rob's nix flake config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-search-github.url = "github:peterldowns/nix-search-cli";
    nix-search-github.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nills.url = "github:oxalica/nil";
    nills.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { nix-search-github, nixpkgs, flake-utils, nills, neovim-nightly-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        robsPackages = with pkgs; [
          neovim-nightly-overlay.packages.${system}.default
          curl
          sqlite-interactive
          ripgrep
          nodejs_latest
          fzf
          rlwrap
          fd
          ffmpeg
          cloudflared
          sqlite-analyzer
          clojure
          jq
          gnugrep
          units
          luajit_openresty
          nmap
          wrk
          watchexec
          wget
          difftastic
          pandoc
          openssh
          imagemagick
          htop
          bat
          babashka
          rsync
          go_1_22
          gh
          git
          shellcheck
          nix-search-github.packages.${system}.default
          nills.packages.${system}.default
          python3Full
          gcc
          gnupg
          devbox
          direnv
          restic
          coreutils
          pinentry_mac
          colima
          docker
          texliveFull
          fish
          cargo
          typescript-language-server
          tree
          zulu
          procps
          clojure-lsp
        ];
      in 
        { 
        packages.default = pkgs.buildEnv {
          name = "development-stuff";
          paths = robsPackages;
        };
      }
    );
}

{
  description = "Rob's nix flake config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-search-github.url = "github:peterldowns/nix-search-cli";
    nix-search-github.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nills.url = "github:oxalica/nil";
    nills.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-search-github, nixpkgs, flake-utils, nills, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        robsPackages = with pkgs; [
          neovim
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
          stow
          tree
          zulu
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

{
  description = "Rob's nix flake config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nix-search-github.url = "github:peterldowns/nix-search-cli";
    nix-search-github.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nix-search-github, nixpkgs, nixpkgs-master, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        base = with pkgs; [
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
          git
          shellcheck
          nix-search-github.packages.${system}.default
          nil
          python3Full
          gcc
          gnupg
          devbox
          direnv
          restic
          coreutils
          fish
          podman
          cargo
          typescript-language-server
          tree
          zulu23
          procps
          clojure-lsp
          clj-kondo
          unzip
          nixpkgs-master.legacyPackages.${system}.jujutsu
          astro-language-server
          clojure-lsp
          pyright
          rust-analyzer
          bash-language-server
          clang-tools
          jdt-language-server
          vscode-langservers-extracted
          zls
          mdx-language-server
          lemminx
          yaml-language-server

          # Mac packages
          colima
        ];
      in 
        { 
          packages.default = pkgs.buildEnv {
            name = "base";
            paths = base;
          };
        }
    );
}

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
        master = nixpkgs-master.legacyPackages.${system};
        base = with pkgs; [
          neovim
          curl
          sqlite-interactive
          sqlite-analyzer
          ripgrep
          fzf
          rlwrap
          fd
          cloudflared
          clojure
          jq
          gnugrep
          watchexec
          wget
          difftastic
          openssh
          htop
          bat
          babashka
          rsync
          git
          shellcheck
          nix-search-github.packages.${system}.default
          nil
          nixfmt-rfc-style
          gcc
          direnv
          restic
          coreutils
          fish
          typescript-language-server
          tree
          zulu25
          procps
          clojure-lsp
          clj-kondo
          unzip
          jujutsu
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
          tailscale
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

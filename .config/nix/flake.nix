{
  description = "Rob's nix flake config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-search-github.url = "github:peterldowns/nix-search-cli";
    nix-search-github.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nix-search-github, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
        macPackages = with pkgs; [
            pinentry_mac
            colima
            texliveFull
        ];
        robsPackages = with pkgs; [
          neovim-unwrapped
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
          nil
          python3Full
          gcc
          gnupg
          devbox
          direnv
          restic
          coreutils
          docker
          fish
          cargo
          typescript-language-server
          tree
          zulu
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
        ];
      in 
        { 
          packages.personal-mac = pkgs.buildEnv {
            name = "personal-mac";
            paths = robsPackages ++ macPackages;
          };
          packages.default = pkgs.buildEnv {
            name = "rob-base";
            paths = robsPackages;
          };
        }
    );
}

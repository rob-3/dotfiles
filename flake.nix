{
  description = "Rob's nix flake config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-search-github.url = "github:peterldowns/nix-search-cli";
    nix-search-github.inputs.nixpkgs.follows = "nixpkgs";
    #neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    #nixpkgs-master.url = "github:NixOS/nixpkgs/master";
  };

  outputs = { self, nix-darwin, nix-search-github, /*neovim-nightly-overlay, nixpkgs-master,*/ ... }:
    {
      darwinConfigurations."ouroboros" = nix-darwin.lib.darwinSystem {
        modules = [
          #({ ... }: { nixpkgs.overlays = [neovim-nightly-overlay.overlays.default]; })
          ({ pkgs, ... }: {
            environment.systemPackages = with pkgs; [
              neovim
              curl
              uutils-coreutils-noprefix
              sqlite-interactive
              ripgrep
              kitty
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
              #bun
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
              nix-search-github.packages.aarch64-darwin.default
              python3Full
              gcc
              gnupg
              texliveFull
              colima # this is for containers/docker
              docker
              devbox
              direnv
              ruff-lsp
              restic
              #nvd
              #vscode
              rectangle
              pure-prompt
              pinentry_mac
              keepassxc
            ];
          })
          ({ config, lib, pkgs, ... }: {
            users.users.rob = {
              name = "rob";
              home = "/Users/rob";
            };
            fonts.packages = [
              pkgs.inconsolata-nerdfont
            ];

            # Auto upgrade nix package and the daemon service.
            services.nix-daemon.enable = true;
            nix.package = pkgs.nix;

            # Necessary for using flakes on this system.
            nix.settings.experimental-features = "nix-command flakes";
            nix.settings.trusted-users = [ "root" "rob" ];

            # Create /etc/zshrc that loads the nix-darwin environment.
            programs.zsh.enable = true; # default shell on catalina
            programs.zsh.enableSyntaxHighlighting = true;
            programs.zsh.promptInit = "autoload -Uz promptinit && promptinit && prompt pure && setopt prompt_sp";
            programs.zsh.interactiveShellInit = ''
              source "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
              source "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
            '';
            environment.shells = [ pkgs.zsh ];
            environment.systemPath = ["/opt/homebrew/bin/"];
            environment.loginShell = pkgs.zsh;

            # Set Git commit hash for darwin-version.
            system.configurationRevision = self.rev or self.dirtyRev or null;

            # Used for backwards compatibility, please read the changelog before changing.
            # $ darwin-rebuild changelog
            system.stateVersion = 4;

            # see https://github.com/LnL7/nix-darwin/blob/master/modules/system/activation-scripts.nix
            system.activationScripts.postUserActivation.text = ''
              rsyncArgs="--archive --checksum --chmod=-w --copy-unsafe-links --delete"
              apps_source="${config.system.build.applications}/Applications"
              moniker="Nix Trampolines"
              app_target_base="$HOME/Applications"
              app_target="$app_target_base/$moniker"
              mkdir -p "$app_target"
              ${pkgs.rsync}/bin/rsync $rsyncArgs "$apps_source/" "$app_target"
            '';

            # The platform the configuration will be used on.
            nixpkgs.hostPlatform = "aarch64-darwin";

            security.pam.enableSudoTouchIdAuth = true;

            system.keyboard.enableKeyMapping = true;
            system.keyboard.remapCapsLockToControl = true;

            #nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
            #  "vscode"
            #];
          })
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."ouroboros".pkgs;
    };
}

# Nix
if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
	source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
end
# End Nix

# cloud CLI tool
fish_add_path ~/cloud/bin/
fish_add_path ~/bills/bin/
fish_add_path ~/.local/bin/

# XDG paths for pi (pi itself only knows ~/.pi/agent)
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_STATE_HOME; or set -gx XDG_STATE_HOME $HOME/.local/state
set -gx PI_CODING_AGENT_DIR $XDG_CONFIG_HOME/pi/agent
set -gx PI_CODING_AGENT_SESSION_DIR $XDG_STATE_HOME/pi/sessions

if status is-interactive
	# Commands to run in interactive sessions can go here
	fish_vi_key_bindings
	bind -M insert \c] accept-autosuggestion execute
	bind -M insert \cp history-prefix-search-backward
	bind -M insert \cn history-prefix-search-forward
	bind -M insert \cy execute
	# Emulates vim's cursor shape behavior
	# Set the normal and visual mode cursors to a block
	set fish_cursor_default block
	# Set the insert mode cursor to a line
	set fish_cursor_insert line
	# Set the replace mode cursors to an underscore
	set fish_cursor_replace_one underscore
	set fish_cursor_replace underscore
	# Set the external cursor to a line. The external cursor appears when a command is started.
	# The cursor shape takes the value of fish_cursor_default when fish_cursor_external is not specified.
	set fish_cursor_external line
	# The following variable can be used to configure cursor shape in
	# visual mode, but due to fish_cursor_default, is redundant here
	set fish_cursor_visual block

	abbr vimrc "nvim ~/.config/nvim/init.lua"
	abbr vimdiff "nvim -d"
	abbr shell --set-cursor "nix shell nixpkgs#%"
	abbr ntfy --set-cursor "curl https://rob-3.dev/ntfy/general -d \"%\""
	abbr until --set-cursor "while not %; sleep 1; end"
	# Credentials never enter the jail. pi only ever sees a throwaway placeholder;
	# the host-side jail-proxy intercepts TLS to openrouter.ai and substitutes the
	# real key from auth.json. Nothing under ~/.config/pi is writable except the
	# session store, so the jail cannot plant config a later host-side pi loads.
	abbr pi "jail -E PI_CODING_AGENT_DIR -E HOME -r ~/.config/pi/agent/settings.json -r ~/.config/pi/agent/APPEND_SYSTEM.md -d ~/.config/pi/agent/sessions -a openrouter.ai --mitm-ca ~/.local/state/jail-proxy --inject-auth-from ~/.config/pi/agent/auth.json -e OPENROUTER_API_KEY=jail-placeholder-0000 -- pi"

	set fish_greeting

	if test (uname) = "Darwin"
		eval (/opt/homebrew/bin/brew shellenv)
	end

	set -gx EDITOR nvim

	set fish_prompt_pwd_dir_length 0

	# Set up fzf key bindings
	fzf --fish | source
end

function fish_prompt --description 'Write out the prompt'
	set -l last_pipestatus $pipestatus
	set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
	set -l normal (set_color normal)
	set -q fish_color_status
	or set -g fish_color_status red

	set -l fish_color_cwd blue
	# Color the prompt differently when we're root
	set -l color_cwd $fish_color_cwd
	set -l suffix '❯'
	if functions -q fish_is_root_user; and fish_is_root_user
		if set -q fish_color_cwd_root
			set color_cwd $fish_color_cwd_root
		end
		set suffix '#'
	end

	# Write pipestatus
	# If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
	set -l bold_flag --bold
	set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
	if test $__fish_prompt_status_generation = $status_generation
		set bold_flag
	end
	set __fish_prompt_status_generation $status_generation
	set -l status_color (set_color $fish_color_status)
	set -l statusb_color (set_color $bold_flag $fish_color_status)
	set -l prompt_color (set_color magenta)
	set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

	set -l nix_shell_info (
	if test -n "$IN_NIX_SHELL"
		echo -n " <nix-shell> "
	end
	)

	echo -n -s (set_color $color_cwd) (prompt_pwd) $normal $nix_shell_info " " $prompt_status \n$prompt_color $suffix " "
end

function fish_mode_prompt
end

function postexec_test --on-event fish_postexec
   echo
end

# function shell
# 	set packages (string replace -r '^' 'nixpkgs#' $argv)
# 	nix shell --offline $packages --command fish
# end

function review-download
	node code-review/download-client/dist/index.js $argv
end

function update
	if test (hostname) = "ouroboros.local"
		brew update && brew upgrade && brew upgrade --cask --greedy
	end
	if test (hostname) = "debian"
		sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
	end
	cd ~/.config/nix/nixos && nix flake update && sudo nixos-rebuild switch && ls /nix/var/nix/profiles/ | sort -V | tail -n 2 | awk "{print \"/nix/var/nix/profiles/\" \$0}" - | xargs nix run nixpkgs#nvd diff
	cd -
end

function dotfiles
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
end

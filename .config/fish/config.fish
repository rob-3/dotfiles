# Nix
if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
	source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
end
# End Nix

# cloud CLI tool
fish_add_path ~/cloud/bin/
fish_add_path ~/bills/bin/

if status is-interactive
	# Commands to run in interactive sessions can go here
	fish_vi_key_bindings
	bind -M insert \c] accept-autosuggestion execute
	bind -M insert \cp history-prefix-search-backward
	bind -M insert \cn history-prefix-search-forward
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
	#alias ssh="kitty +kitten ssh"
	#abbr ssh "wezterm ssh"
	abbr vimdiff "nvim -d"
	#alias icat="kitty +kitten icat"
	#abbr icat "wezterm imgcat"
	abbr g "nvim +':GpChatNew'"
	abbr shell --set-cursor "nix shell --offline nixpkgs#% --command fish "
	abbr ntfy --set-cursor "curl https://rob-3.dev/ntfy/general -d \"%\""

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

	echo -n -s (set_color $color_cwd) (prompt_pwd) $normal " " $prompt_status \n$prompt_color $suffix " "
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
	cd ~/.config/nix && nix flake update && nix profile upgrade nix && ls ~/.local/state/nix/profiles | sort -V | tail -n 2 | awk "{print \"$HOME/.local/state/nix/profiles/\" \$0}" - | xargs nix run nixpkgs#nvd diff
	cd -
end

function dotfiles
	git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
end

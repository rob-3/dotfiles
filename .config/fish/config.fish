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

	abbr vimrc "nvim ~/.config/nvim/lua/rob-3/init.lua"
    #alias ssh="kitty +kitten ssh"
    #abbr ssh "wezterm ssh"
	abbr vimdiff "nvim -d"
    #alias icat="kitty +kitten icat"
    #abbr icat "wezterm imgcat"
	abbr g "nvim +':GpChatNew'"

	set fish_greeting

	eval (/opt/homebrew/bin/brew shellenv)

	set __fish_git_prompt_show_informative_status 1
	set __fish_git_prompt_showdirtystate 1
	set __fish_git_prompt_showuntrackedfiles 1
	set __fish_git_prompt_showstashstate 1
	set __fish_git_prompt_char_cleanstate ""
	set __fish_git_prompt_char_dirtystate "*"
	set __fish_git_prompt_char_stashstate "≡"

	set -gx EDITOR nvim
end

function fish_git_prompt
    set -l branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test $status -eq 0
        set_color 6c6c6c
        echo -n " $branch"
        
        # Check for untracked or dirty files
        if not command git diff-index --quiet HEAD -- 2>/dev/null
            or count (git ls-files --others --exclude-standard) >/dev/null
            set_color ffafd7
            echo -n "*"
        end
        
        # Check upstream status
        set -l upstream (git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
        if test $status -eq 0
            set -l behind (git rev-list --count HEAD..$upstream 2>/dev/null)
            set -l ahead (git rev-list --count $upstream..HEAD 2>/dev/null)
            
            set_color cyan
            if test $behind -gt 0 -a $ahead -gt 0
                echo -n " ⇣⇡"
            else if test $behind -gt 0
                echo -n " ⇣"
            else if test $ahead -gt 0
                echo -n " ⇡"
            end
        end
        
        # Check for stashes
        set -l stash_count (git stash list | wc -l | tr -d ' ')
        if test $stash_count -gt 0
            set_color cyan
            echo -n " ≡"
        end
        
        echo -n " "
        set_color normal
    end
end

# name: Default
# author: Lily Ballard

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

    echo -n -s (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status \n$prompt_color $suffix " "
end

function fish_mode_prompt
end

function postexec_test --on-event fish_postexec
   echo
end

function shell
    set packages (string replace -r '^' 'nixpkgs#' $argv)
    nix shell $packages --command fish
end

function review-download
    node code-review/download-client/dist/index.js $argv
end

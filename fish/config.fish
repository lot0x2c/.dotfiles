# Environment is also needed by noninteractive shells.
fish_add_path -g ~/.local/bin ~/.config/emacs/bin
status is-interactive; or return

set -g fish_greeting

# vi keys; ctrl-f still accepts the autosuggestion
set -g fish_key_bindings fish_vi_key_bindings
function fish_user_key_bindings
    for mode in insert default visual
        bind -M $mode ctrl-f forward-char
    end
end
set -g fish_cursor_insert block
set -g fish_cursor_replace_one block
set -g fish_cursor_replace block

if status is-interactive
    abbr -a snv sudoedit
    abbr -a md mkdir
    abbr -a clr clear
    abbr -a rf rm -rf
    abbr -a cpr cp -r
    abbr -a lb lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
    abbr -a nrd npm run dev
    abbr -a sfc source ~/.config/fish/config.fish

    # navigation / files
    abbr -a .. cd ..
    abbr -a ... cd ../..
    abbr -a .... cd ../../..
    abbr -a dot cd ~/.config/.dotfiles
    abbr -a ll ls -lah
    abbr -a dud 'du -h --max-depth=1 | sort -h'
    abbr -a df df -h
    abbr -a mv mv -iv
    abbr -a cpv cp -iv

    # editors
    abbr -a v nvim
    abbr -a vf nvim ~/.config/.dotfiles/fish/config.fish
    abbr -a vn nvim ~/.config/.dotfiles/nixos/configuration.nix
end

# mkdir + cd
function mkcd
    if test (count $argv) -ne 1
        echo 'usage: mkcd DIRECTORY' >&2
        return 2
    end
    mkdir -p -- $argv[1]; and cd -- $argv[1]
end

# extract anything
function x
    if test (count $argv) -ne 1; or not test -f "$argv[1]"
        echo 'usage: x ARCHIVE' >&2
        return 2
    end
    switch $argv[1]
        case '*.tar.gz' '*.tgz'; tar xzf $argv[1]
        case '*.tar.xz';         tar xJf $argv[1]
        case '*.tar.bz2';        tar xjf $argv[1]
        case '*.zip';            unzip $argv[1]
        case '*.7z';             7z x $argv[1]
        case '*';                echo "don't know how to extract $argv[1]" >&2; return 2
    end
end

# plocate wrapper: loc [-d DIR] PATTERN
#   loc '*.pdf'              everywhere
#   loc -d ~/temp '*.pdf'    only under ~/temp
#   loc -d ~/temp report     substring match under ~/temp
# searches the existing index, loc-refresh updates it
function loc
    argparse 'd/dir=' -- $argv; or return
    if test (count $argv) -eq 0
        echo "usage: loc [-d DIR] PATTERN" >&2
        return 1
    end
    set -l pat $argv[1]
    string match -qr '\*|\?|\[' -- $pat; or set pat "*$pat*"
    if set -q _flag_dir
        set -l dir (path resolve $_flag_dir)
        plocate -i -- "$dir/$pat"
    else
        plocate -i -- $pat
    end
end

# rebuilds the index. loc never does this on its own
function loc-refresh
    sudo updatedb
end

# cd to where yazi quit (q, not Q)
function y
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and test "$cwd" != "$PWD"; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end


# bubblegum
set -g fish_color_normal normal
set -g fish_color_command 00a2b8
set -g fish_color_keyword f030a8
set -g fish_color_quote 08c7a4
set -g fish_color_redirection f030a8
set -g fish_color_end c13fd2
set -g fish_color_error ed286f
set -g fish_color_param normal
set -g fish_color_comment 745268
set -g fish_color_operator 00b9a3
set -g fish_color_escape bf5e87
set -g fish_color_autosuggestion 745268
set -g fish_color_search_match --background=e0ccd1 352930
set -g fish_color_selection --background=e0ccd1 352930
set -g fish_color_cancel ed286f
set -g fish_pager_color_prefix f030a8 --bold
set -g fish_pager_color_completion normal
set -g fish_pager_color_description 00b9a3
set -g fish_pager_color_progress --background=e0ccd1 352930
set -g fish_pager_color_selected_background --background=e0ccd1
set -g fish_pager_color_selected_prefix cb2762 --bold
set -g fish_pager_color_selected_completion 352930
set -g fish_pager_color_selected_description 5c4250

#   [~/full/path][git:main*][i][!1]
#   λ                                            ><>
set -g fish_prompt_pwd_dir_length 0
set -g __fish_git_prompt_showdirtystate yes
set -g __fish_git_prompt_char_stateseparator ''
set -g __fish_git_prompt_color_branch 00a2b8
set -g __fish_git_prompt_color_dirtystate f030a8
set -g __fish_git_prompt_color_stagedstate 08c7a4
function fish_mode_prompt; end
# git once per prompt, not on every repaint (vi mode switches repaint)
function __prompt_git_stale --on-event fish_prompt
    set -e __prompt_git_dir
end
function fish_prompt
    set -l last $status
    set -l grey 745268
    set -l cwd (prompt_pwd)
    if test "$__prompt_git_dir" != "$PWD"
        set -g __prompt_git_dir $PWD
        set -g __prompt_git (fish_git_prompt %s)
    end
    set -l mode n 00a2b8
    switch $fish_bind_mode
        case insert
            set mode i 08c7a4
        case visual
            set mode v f030a8
        case replace replace_one
            set mode r ed286f
    end

    set_color $grey; echo -n '['
    set_color f030a8; echo -n (string replace -r '[^/]*$' '' -- $cwd)
    set_color f030a8 --bold; echo -n (string match -r '[^/]*$' -- $cwd)
    set_color normal; set_color $grey; echo -n ']'
    if test -n "$__prompt_git"
        echo -n "[git:$__prompt_git"; set_color $grey; echo -n ']'
    end
    echo -n '['; set_color $mode[2]; echo -n $mode[1]; set_color $grey; echo -n ']'
    if test $last -ne 0
        echo -n '['; set_color ed286f; echo -n "!$last"; set_color $grey; echo -n ']'
    end
    echo
    set_color 08c7a4
    fish_is_root_user; and echo -n '# '; or echo -n 'λ '
    set_color normal
end
function fish_right_prompt
    set_color bf5e87; echo -n '><>'; set_color normal
end

# last, so sway inherits everything above. log: journalctl -t sway -b -1
if status is-login; and test -z "$WAYLAND_DISPLAY"; and test (tty) = /dev/tty1
    set -gx XDG_SESSION_TYPE wayland
    exec systemd-cat -t sway sway
end

#!/usr/bin/env fish
# jail — run a command inside a hardened bubblewrap (bwrap) sandbox.
#
#   usage: jail [-d PATH]... [-r PATH]... [-e VAR=VAL]... [-E VAR]... -- COMMAND [ARGS...]
#
# Requires: bubblewrap (bwrap), fish >= 3.5, and unprivileged user
# namespaces enabled (or a setuid bwrap binary).

function jail_usage
    echo "usage: jail [-d PATH]... [-r PATH]... [-e VAR=VAL]... [-E VAR]... -- COMMAND [ARGS...]"
    echo "  -d PATH     bind PATH (dir or file) read-write into the jail (repeatable)"
    echo "  -r PATH     bind PATH (dir or file) read-only  into the jail (repeatable)"
    echo "  -e VAR=VAL  set environment variable VAR inside the jail (repeatable)"
    echo "  -E VAR      pass VAR through from the host, if set (repeatable)"
    echo "  --          everything after this is executed inside the jail"
end

if not command -sq bwrap
    echo "jail: bwrap (bubblewrap) is required but not installed" >&2
    exit 1
end

set -l rw_dirs
set -l ro_dirs
set -l user_env   # flat list: NAME VALUE NAME VALUE ...

while set -q argv[1]
    if test "$argv[1]" = "--"           # end of options: the rest is the command
        set -e argv[1]
        break
    end
    switch $argv[1]
        case -d -r
            if not set -q argv[2]
                echo "jail: $argv[1] requires a path argument" >&2
                exit 1
            end
            if not test -e "$argv[2]"
                echo "jail: no such file or directory: $argv[2]" >&2
                exit 1
            end
            if test "$argv[1]" = -d
                set -a rw_dirs (path resolve -- $argv[2])
            else
                set -a ro_dirs (path resolve -- $argv[2])
            end
            set -e argv[1..2]
        case -e
            if not set -q argv[2]; or not string match -qr -- '^[A-Za-z_][A-Za-z0-9_]*=' $argv[2]
                echo "jail: -e requires VAR=VALUE" >&2
                exit 1
            end
            set -l kv (string split -m1 = -- $argv[2])
            set -a user_env $kv[1] "$kv[2]"
            set -e argv[1..2]
        case -E
            if not set -q argv[2]; or not string match -qr -- '^[A-Za-z_][A-Za-z0-9_]*$' $argv[2]
                echo "jail: -E requires a variable name" >&2
                exit 1
            end
            if set -q $argv[2]
                set -a user_env $argv[2] (string join : -- $$argv[2])
            end
            set -e argv[1..2]
        case -h --help
            jail_usage
            exit 0
        case '-*'
            echo "jail: unknown option: $argv[1]" >&2
            jail_usage >&2
            exit 1
        case '*'
            echo "jail: expected '--' before the command (got '$argv[1]')" >&2
            jail_usage >&2
            exit 1
    end
end

if not set -q argv[1]
    echo "jail: no command given" >&2
    jail_usage >&2
    exit 1
end

set -l cmd

# ---- isolation ---------------------------------------------------------
# --unshare-all = new user, ipc, pid, uts and cgroup namespaces.
# --share-net   = the one exception: keep the host network namespace.
set -a cmd \
    --unshare-all \
    --unshare-user \
    --share-net \
    --cap-drop ALL \
    --die-with-parent \
    --hostname jail \
    --clearenv \
    --setenv HOME /tmp \
    --setenv TMPDIR /tmp

# PATH: standard FHS dirs, plus NixOS system/user profiles when present
# (those live under /run and /etc and point into /nix/store).
set -l jail_path
for p in /run/current-system/sw/bin /etc/profiles/per-user/$USER/bin \
        /usr/local/bin /usr/bin /bin /usr/sbin /sbin
    if test -d $p
        set -a jail_path $p
    end
end
set -a cmd --setenv PATH (string join : -- $jail_path)

for var in TERM LANG LC_ALL COLORTERM LOCALE_ARCHIVE TZDIR
    if set -q $var
        set -a cmd --setenv $var $$var
    end
end

# User-supplied env last, so it overrides the defaults above (e.g. HOME).
for i in (seq 1 2 (count $user_env))
    set -a cmd --setenv $user_env[$i] $user_env[(math $i + 1)]
end

# Defense in depth: forbid creating further user namespaces inside the
# jail (bwrap >= 0.8; probed so older versions still work).
set -l bhelp (bwrap --help 2>/dev/null)
if set -q bhelp[1]; and string match -q -- '*--disable-userns*' $bhelp
    set -a cmd --disable-userns
end

# ---- filesystem --------------------------------------------------------
# Fresh /proc, minimal /dev, private scratch space, then the read-only
# host trees a normal program needs. bwrap auto-creates missing
# destination directories.
set -a cmd \
    --proc /proc \
    --dev /dev \
    --perms 1777 --tmpfs /dev/shm \
    --perms 1777 --tmpfs /tmp \
    --perms 1777 --tmpfs /var/tmp \
    --tmpfs /run \
    --ro-bind-try /usr /usr \
    --ro-bind-try /etc /etc \
    --ro-bind-try /sys /sys

# NixOS / Nix: everything real lives in /nix/store; /run holds the
# entry-point symlinks, which must be recreated on top of the /run tmpfs.
if test -d /nix
    set -a cmd --ro-bind /nix /nix
    for link in /run/current-system /run/booted-system /run/opengl-driver /run/opengl-driver-32
        if test -L $link
            set -a cmd --symlink (readlink -- $link) $link
        end
    end
end

# /bin, /sbin, /lib*: recreate the symlinks on usr-merged systems,
# bind the real directories otherwise.
for name in bin sbin lib lib32 lib64
    if test -L "/$name"
        set -l target (readlink -- "/$name")
        if set -q target[1]
            set -a cmd --symlink "$target" "/$name"
        end
    else if test -d "/$name"
        set -a cmd --ro-bind-try "/$name" "/$name"
    end
end

# Keep DNS working when /etc/resolv.conf points outside /etc (e.g.
# systemd-resolved links it into /run/systemd/resolve).
# `path resolve` follows the full symlink chain, so relative links like
# ../run/systemd/resolve/stub-resolv.conf are handled too.
if test -L /etc/resolv.conf
    set -l resolv (path resolve -- /etc/resolv.conf)
    if set -q resolv[1]; and not string match -q -- '/etc/*' "$resolv"; and not string match -q -- '/usr/*' "$resolv"
        set -l resolv_dir (path dirname -- "$resolv")
        set -a cmd --ro-bind-try "$resolv_dir" "$resolv_dir"
    end
end

# ---- user bindings (added last, so they can shadow the defaults) -------
for d in $rw_dirs
    set -a cmd --bind "$d" "$d"
end
for d in $ro_dirs
    set -a cmd --ro-bind "$d" "$d"
end

# ---- working directory --------------------------------------------------
# Land in the current directory if a bound tree covers it, or if a bound
# tree lies below it (bwrap creates the missing parent dirs), else in /.
set -l cwd (path resolve -- $PWD)
set -l start /
for d in $rw_dirs $ro_dirs
    if test "$cwd" = "$d"; or test "$d" = /
        set start "$cwd"
        break
    end
    # literal prefix check (no globbing on $d)
    set -l prefix "$d/"
    if test (string sub -l (string length -- "$prefix") -- "$cwd") = "$prefix"
        set start "$cwd"
        break
    end
    # The binding may be *below* the cwd. bwrap creates missing parent
    # directories for mount destinations, so $cwd will exist as an
    # auto-created directory and we can still chdir there.
    set -l cprefix "$cwd/"
    if test (string sub -l (string length -- "$cprefix") -- "$d") = "$cprefix"
        set start "$cwd"
        break
    end
end
set -a cmd --chdir "$start"

exec bwrap $cmd -- $argv

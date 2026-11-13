#!/usr/bin/env fish
# jail — run a command inside a hardened bubblewrap (bwrap) sandbox.
#
#   usage: jail [-d PATH]... [-r PATH]... [-e VAR=VAL]... [-E VAR]...
#               [-a TARGET]... [--net-public|--net-host] [-- COMMAND [ARGS...]]
#
# Network: by default the jail gets a private namespace whose only reachable
# endpoint is a proxy that only forwards destinations listed with -a/--allow
# (address, CIDR, hostname, optional :port); everything else is refused,
# private and public alike, and DNS resolution happens on the host.
# --net-public allows any public internet destination (with -a as extra
# exceptions); --net-host opts out completely and shares the host network
# namespace. The proxy speaks HTTP(S) on
# 127.0.0.1:8787 and SOCKS5 on 127.0.0.1:1080 for arbitrary TCP. Only the
# -a/--allow entries are reachable (private and public alike).
#
# Requires: bubblewrap (bwrap), fish >= 3.5, and unprivileged user
# namespaces enabled (or a setuid bwrap binary). --net-public additionally
# needs bb and unshare(1), plus jail-proxy.bb and jail-bridge.bb next to
# this script.

function jail_usage
    echo "usage: jail [-d PATH]... [-r PATH]... [-e VAR=VAL]... [-E VAR]..."
    echo "            [--net-public|--net-host] [-- COMMAND [ARGS...]]"
    echo "  -d PATH     bind PATH (dir or file) read-write into the jail (repeatable)"
    echo "  -r PATH     bind PATH (dir or file) read-only  into the jail (repeatable)"
    echo "  -e VAR=VAL  set environment variable VAR inside the jail (repeatable)"
    echo "  -E VAR      pass VAR through from the host, if set (repeatable)"
    echo "  -a TARGET   whitelist TARGET for the network policy (repeatable):"
    echo "              ADDR, CIDR, HOST, HOST:PORT, ADDR:PORT  (also \$JAIL_ALLOW)"
    echo "  (default)    private netns, only -a entries reachable: HTTP(S) on"
    echo "                127.0.0.1:8787, SOCKS5 on 127.0.0.1:1080 for any TCP"
    echo "  --net-public allow any public internet destination (-a adds exceptions)"
    echo "  --net-allowlist  same as the default; kept for compatibility"
    echo "  --net-host   share the host network namespace (no policy; opt-out)"
    echo "  --mitm-ca DIR        intercept TLS CONNECT with the CA in DIR (generated"
    echo "                       on first use) and export only that CA to the jail"
    echo "  --mitm-port PORT     port to intercept (default 443)"
    echo "  --inject-auth-from FILE   replace Authorization with the key from a pi"
    echo "                       auth.json; needs --mitm-ca (default provider openrouter)"
    echo "  --inject-auth-env VAR     same, reading the key from the host environment"
    echo "  --inject-auth-provider P  auth.json entry to use (default openrouter)"
    echo "  --          everything after this is executed inside the jail"
end

if not command -sq bwrap
    echo "jail: bwrap (bubblewrap) is required but not installed" >&2
    exit 1
end

set -l rw_dirs
set -l ro_dirs
set -l user_env      # flat list: NAME VALUE NAME VALUE ...
set -l net_mode allowlist # allowlist (default) | public | host (--net-host)
set -l allow_entries # network whitelist: ADDR, CIDR, HOST, HOST:PORT
set -l mitm_ca       # TLS intercept dir; its ca.pem is exported to the jail
set -l mitm_port     # port whose CONNECT tunnels get intercepted
set -l inject_file   # pi auth.json read on the host for the real credential
set -l inject_env    # host env var holding the real credential
set -l inject_provider openrouter
set -l real_uid (id -u)
set -l real_gid (id -g)

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
        case -a --allow
            if not set -q argv[2]
                echo "jail: $argv[1] requires an address, CIDR or hostname" >&2
                exit 1
            end
            set -a allow_entries $argv[2]
            set -e argv[1..2]
        case --net-public
            set net_mode public
            set -e argv[1]
        case --net-host
            set net_mode host
            set -e argv[1]
        case --net-allowlist
            set net_mode allowlist
            set -e argv[1]
        case --mitm-ca
            if not set -q argv[2]
                echo "jail: $argv[1] requires a directory" >&2
                exit 1
            end
            set mitm_ca (path normalize -- $argv[2])
            set -e argv[1..2]
        case --mitm-port
            if not set -q argv[2]; or not string match -qr -- '^[0-9]+$' $argv[2]
                echo "jail: $argv[1] requires a port number" >&2
                exit 1
            end
            set mitm_port $argv[2]
            set -e argv[1..2]
        case --inject-auth-from
            if not set -q argv[2]
                echo "jail: $argv[1] requires a file" >&2
                exit 1
            end
            set inject_file (path normalize -- $argv[2])
            set -e argv[1..2]
        case --inject-auth-env
            if not set -q argv[2]; or not string match -qr -- '^[A-Za-z_][A-Za-z0-9_]*$' $argv[2]
                echo "jail: $argv[1] requires a variable name" >&2
                exit 1
            end
            set inject_env $argv[2]
            set -e argv[1..2]
        case --inject-auth-provider
            if not set -q argv[2]
                echo "jail: $argv[1] requires a provider name" >&2
                exit 1
            end
            set inject_provider $argv[2]
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

if set -q JAIL_ALLOW
    for entry in (string split -n ' ' -- (string replace -a ',' ' ' $JAIL_ALLOW))
        set -a allow_entries $entry
    end
end
if test "$net_mode" = host; and set -q allow_entries[1]
    echo "jail: warning: -a/--allow has no effect with --net-host" >&2
end
if test "$net_mode" = host; and test -n "$mitm_ca$inject_file$inject_env"
    echo "jail: --mitm-ca/--inject-auth-* need the network policy (not --net-host)" >&2
    exit 1
end
if test -z "$mitm_ca"; and test -n "$inject_file$inject_env"
    echo "jail: --inject-auth-* requires --mitm-ca (a CONNECT tunnel hides headers)" >&2
    exit 1
end
set -l ossl
if test -n "$mitm_ca"
    set ossl (command -s openssl)
    if test -z "$ossl"
        # NixOS: the CLI is often not in the system profile but is in the store.
        set -l cand /nix/store/*openssl*/bin/openssl
        for c in $cand
            if test -x "$c"
                set ossl $c
                break
            end
        end
    end
    if test -z "$ossl"
        echo "jail: --mitm-ca needs openssl (not on PATH, none in /nix/store)" >&2
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
# --share-net   = the one exception: keep the network namespace. By default
#                 that is the private namespace created by unshare(1) at the
#                 end of this script; with --net-host it is the host's.
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
if test "$net_mode" != host; and string match -q -- '*--uid*' $bhelp
    # Public networking starts us as uid 0 in a wrapper user namespace; map the
    # real user back so the jail keeps its normal identity.
    set -a cmd --uid $real_uid --gid $real_gid
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

# TLS interception: export the proxy's CA (and only its public half) so the
# jail trusts the re-signed upstream. The key never leaves the host.
if set -q mitm_ca[1]
    set -l ca_cert "$mitm_ca/ca.pem"
    set -a cmd --ro-bind "$ca_cert" "$ca_cert"
    for var in NODE_EXTRA_CA_CERTS SSL_CERT_FILE CURL_CA_BUNDLE REQUESTS_CA_BUNDLE GIT_SSL_CAINFO
        set -a cmd --setenv $var "$ca_cert"
    end
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

if test "$net_mode" = host
    exec bwrap $cmd -- $argv
end

# ---- network policy (default) ------------------------------------------
# The jail runs in its own network namespace with loopback only. The only
# reachable endpoints are 127.0.0.1:8787 (HTTP/S proxy) and 127.0.0.1:1080
# (SOCKS5, same listener), bridged over a unix socket to jail-proxy on the
# host. jail-proxy refuses every destination that is not public internet
# unless it matches -a/--allow. Nothing here changes host networking: it only
# listens on a unix socket.
for tool in bb unshare
    if not command -sq $tool
        echo "jail: $tool is required for the network policy (or use --net-host)" >&2
        exit 1
    end
end

set -l helper (path dirname (path resolve (status filename)))
set -l proxy_exe "$helper/jail-proxy.bb"
if not test -x "$proxy_exe"; or not test -x "$helper/jail-bridge.bb"
    echo "jail: network policy needs jail-proxy.bb and jail-bridge.bb in $helper" >&2
    exit 1
end

set -a cmd \
    --setenv HTTP_PROXY http://127.0.0.1:8787 \
    --setenv HTTPS_PROXY http://127.0.0.1:8787 \
    --setenv ALL_PROXY socks5h://127.0.0.1:1080 \
    --setenv NO_PROXY ''

set -l state (mktemp -d)
chmod 700 $state

set -l proxy_args --listen "unix:$state/proxy.sock"
for entry in $allow_entries
    set -a proxy_args --allow $entry
end
if test "$net_mode" = allowlist
    set -a proxy_args --allow-only
end
if set -q mitm_ca[1]
    set -a proxy_args --mitm-ca "$mitm_ca"
    set -a proxy_args --openssl "$ossl"
    if set -q mitm_port[1]
        set -a proxy_args --mitm-port "$mitm_port"
    end
    if set -q inject_file[1]
        set -a proxy_args --inject-auth-from "$inject_file"
    end
    if set -q inject_env[1]
        set -a proxy_args --inject-auth-env "$inject_env"
    end
    set -a proxy_args --inject-auth-provider "$inject_provider"
end
"$proxy_exe" $proxy_args >"$state/proxy.log" 2>&1 &
set -l proxy_pid $last_pid
for i in (seq 100)
    test -S "$state/proxy.sock"; and break
    sleep 0.05
end
if not test -S "$state/proxy.sock"
    echo "jail: jail-proxy.bb failed to start:" >&2
    cat "$state/proxy.log" >&2
    kill $proxy_pid 2>/dev/null
    rm -rf $state
    exit 1
end

unshare --user --map-root-user --net --fork --kill-child -- \
    "$helper/jail-bridge.bb" --socket "$state/proxy.sock" \
        --port 8787 --port 1080 --ready "$state/ready" -- bwrap $cmd -- $argv
set -l rc $status

kill $proxy_pid 2>/dev/null
wait $proxy_pid 2>/dev/null
if set -q JAIL_DEBUG; and test -s "$state/proxy.log"
    cat "$state/proxy.log" >&2
end
rm -rf $state
exit $rc

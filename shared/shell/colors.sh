# Shared Bash/Zsh helpers. Color overrides accept only #RRGGBB.
_dotfiles_color() {
    case "${1:-}" in
        \#[[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]]) printf '%s' "$1" ;;
        *) printf '%s' "$2" ;;
    esac
}

_dotfiles_path_color() {
    _dotfiles_color "${DOTFILES_PATH_COLOR:-}" 37
}

# Starship styles are static TOML, so keep an overridden copy in the local cache.
# Never modify the tracked template or replace a separate STARSHIP_CONFIG.
_dotfiles_configure_starship() {
    local template="$1" color cache generated temporary
    cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
    generated="$cache/starship-colors.toml"
    color=$(_dotfiles_color "${DOTFILES_PATH_COLOR:-}" '')
    if [ -z "$color" ]; then
        if [ "${STARSHIP_CONFIG:-}" = "$generated" ]; then unset STARSHIP_CONFIG; fi
        return 0
    fi
    case "${STARSHIP_CONFIG:-}" in
        ''|"$template"|"$generated") ;;
        *) return 0 ;;
    esac
    [ -f "$template" ] || return 0
    mkdir -p "$cache" || return
    temporary=$(mktemp "$cache/starship-colors.XXXXXX") || return
    if awk -v color="$color" '
        /^\[/ { directory = ($0 == "[directory]") }
        /^\[directory\]$/ {
            print
            print "style = \"bold " color "\""
            print "repo_root_style = \"bold " color "\""
            next
        }
        directory && /^[[:space:]]*(style|repo_root_style)[[:space:]]*=/ { next }
        { print }
    ' "$template" > "$temporary" && mv "$temporary" "$generated"; then
        export STARSHIP_CONFIG="$generated"
    else
        rm -f "$temporary"
        return 1
    fi
}

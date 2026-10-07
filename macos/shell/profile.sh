# Loaded by ~/.zprofile; supports both Apple Silicon and Intel Homebrew.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
[[ -d "$HOME/flutter/bin" ]] && export PATH="$HOME/flutter/bin:$PATH"
[[ -d "$HOME/.gem/bin" ]] && export PATH="$HOME/.gem/bin:$PATH"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# The versioned Erlang formula is keg-only; use the compatible language-server runtime.
if command -v brew >/dev/null; then
  erlang_prefix="$(brew --prefix erlang@28 2>/dev/null || true)"
  [[ ! -d "$erlang_prefix/bin" ]] || export PATH="$erlang_prefix/bin:$PATH"
  unset erlang_prefix
fi

# A missing optional runtime must not make shell startup fail.
true

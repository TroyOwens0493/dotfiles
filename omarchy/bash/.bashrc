# Keep Omarchy's environment available to non-interactive shells.
[[ ! -r /usr/share/omarchy/default/bash/env-bootstrap ]] || source /usr/share/omarchy/default/bash/env-bootstrap
[[ $- == *i* ]] || return 0

# Keep the defaults provided by the installed Omarchy version.
source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/rc"
source "$HOME/.config/shell/colors.sh"
for dotfiles_part in .bash_aliases .bash_exports .bash_customizations; do
  source "$HOME/.config/shell/omarchy/$dotfiles_part"
done
unset dotfiles_part
[[ ! -r "$HOME/.bashrc.local" ]] || source "$HOME/.bashrc.local"
_dotfiles_configure_starship "$HOME/.config/starship.toml"
# Local color exports are loaded after the shared prompt hooks.
if declare -F _dotfiles_set_prompt >/dev/null; then _dotfiles_set_prompt; fi

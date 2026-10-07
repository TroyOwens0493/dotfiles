# Resolve this file through symlinks so the repo can live at any path.
DOTFILES=${${(%):-%N}:A:h}
source "$DOTFILES/../shell/profile.sh"
source "$DOTFILES/.zsh_aliases"
source "$DOTFILES/.zsh_exports"
source "$DOTFILES/.zsh_customizations"

export NVM_DIR="$HOME/.nvm"
[[ ! -s "$NVM_DIR/nvm.sh" ]] || source "$NVM_DIR/nvm.sh"
[[ ! -s "$NVM_DIR/bash_completion" ]] || source "$NVM_DIR/bash_completion"

# Keep private and machine-specific shell settings outside the repository.
[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"

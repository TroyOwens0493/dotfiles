#!/bin/sh
# Apply validated environment overrides before TPM loads the Dracula theme.
. "$HOME/.config/shell/colors.sh"
# Read the server's exports so a stale session environment cannot hide updates.
server_color() {
    assignment=$(tmux show-environment -g "$1" 2>/dev/null) || assignment=''
    _dotfiles_color "${assignment#*=}" "$2"
}
bar=$(server_color DOTFILES_TMUX_BAR_COLOR '#44475a')
accent=$(server_color DOTFILES_TMUX_BAR_COLOR '#8be9fd')
active=$(server_color DOTFILES_TMUX_ACTIVE_COLOR '#6272a4')
text=$(server_color DOTFILES_TMUX_TEXT_COLOR '#f8f8f2')
tmux set-option -g @dracula-colors "gray=\"$bar\"; cyan=\"$accent\"; dark_purple=\"$active\"; white=\"$text\"; network_blue=\"#8be9fd\""
# Keep the network section cyan even when the bar accent is overridden.
tmux set-option -g @dracula-network-colors 'network_blue dark_gray'

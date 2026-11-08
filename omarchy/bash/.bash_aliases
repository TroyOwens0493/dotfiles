alias glog='git log --oneline --graph --color --all --decorate'
alias lg='lazygit'
alias tm='tmux'
alias cc='claude --model fable --system-prompt ""'
alias claudex='ANTHROPIC_BASE_URL=http://127.0.0.1:8317 ANTHROPIC_AUTH_TOKEN=vibeproxy CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 claude --model gpt-5.6-sol --effort medium'
alias gds='git diff --staged'
alias glp='git log -p'

# Toggle the live Alt/Super swap, preserving all other keyboard options.
_dotfiles_toggle_alt_super() {
    local options_json
    options_json=$(hyprctl -j getoption input:kb_options | jq -ce '
        .str | split(",") |
        if index("altwin:swap_alt_win") then
            map(select(. != "altwin:swap_alt_win"))
        else
            . + ["altwin:swap_alt_win"]
        end |
        map(select(length > 0)) | join(",")
    ') || return

    hyprctl eval "hl.config({input = {kb_options = $options_json}})" >/dev/null || return
    if [[ $options_json == *altwin:swap_alt_win* ]]; then
        printf '%s\n' 'Alt/Super swap enabled (Apple keyboard: Option = Super, Command = Alt).'
    else
        printf '%s\n' 'Alt/Super swap disabled (Apple keyboard: Command = Super, Option = Alt).'
    fi
}
alias toggle-alt-super='_dotfiles_toggle_alt_super'

if command -v mono >/dev/null 2>&1 && [[ -f /usr/local/bin/nuget.exe ]]; then
    alias nuget='mono /usr/local/bin/nuget.exe'
fi

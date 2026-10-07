alias glog='git log --oneline --graph --color --all --decorate'
alias lg='lazygit'
alias tm='tmux'
alias cc='claude --model fable --system-prompt ""'
alias claudex='ANTHROPIC_BASE_URL=http://127.0.0.1:8317 ANTHROPIC_AUTH_TOKEN=vibeproxy CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 claude --model gpt-5.6-sol --effort medium'
alias gd='git diff'
alias gds='git diff --staged'
alias glp='git log -p'
alias d='delta'
if command -v mono >/dev/null 2>&1 && [[ -f /usr/local/bin/nuget.exe ]]; then
    alias nuget='mono /usr/local/bin/nuget.exe'
fi

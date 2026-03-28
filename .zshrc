# ── Shell options ────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

setopt AUTO_CD              # type a directory name to cd into it
setopt AUTO_PUSHD           # cd pushes onto directory stack
setopt PUSHD_IGNORE_DUPS    # no duplicates in dir stack
setopt PUSHD_SILENT         # don't print stack after pushd
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell
setopt COMPLETE_ALIASES     # complete aliases as distinct commands

# ── Completion ───────────────────────────────────────
autoload -Uz compinit && compinit
compdef _files ls la lt ll         # file completion for eza aliases
zstyle ':completion:*' menu select                    # arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # colored completions

# ── Plugins ─────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# ── Prompt ──────────────────────────────────────────
setopt PROMPT_SUBST
PROMPT='%F{240}%n@%m%f %F{255}%~%f %(?.%F{114}.%F{203})❯%f '

# ── History ──────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE    # space-prefixed commands not saved
setopt HIST_REDUCE_BLANKS   # trim extra whitespace

# ── fzf ──────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git'
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_COMPLETION_TRIGGER='**'
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
bindkey '^I' fzf-completion         # Tab: fzf on **, normal completion otherwise

# ── Key bindings ─────────────────────────────────────
bindkey '^[[H'    beginning-of-line    # Home
bindkey '^[[F'    end-of-line          # End
bindkey '^[[3~'   delete-char          # Delete
bindkey '^[[1;5C' forward-word         # Ctrl+Right
bindkey '^[[1;5D' backward-word        # Ctrl+Left
bindkey '^H'      backward-kill-word   # Ctrl+Backspace
bindkey '^[[3;5~' kill-word            # Ctrl+Delete

# ── eza (modern ls) ──────────────────────────────────
alias ls='eza --icons'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias ll='eza -l --icons --git'

# ── Git shortcuts ────────────────────────────────────
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'

# ── System / convenience ─────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ip='ip -color=auto'
alias ports='ss -tulnp'
alias path='echo $PATH | tr ":" "\n"'
alias d='dirs -v | head -15'
alias rg='rg --smart-case'

# ── Custom scripts ──────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/Arch-X/bin:$PATH"

# ── Autosuggestions color ────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#444444"

# ── Syntax highlighting (must be last) ──────────────
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(zoxide init zsh)"        # z <partial-dir> to jump
alias cat='bat --paging=never'   # syntax-highlighted cat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
# Auto-load SSH keys without passphrases
for key in ~/.ssh/*; do
    [[ -f "$key" ]] || continue
    [[ "$key" == *.pub || "$key" == */config || "$key" == */known_hosts* || "$key" == */authorized_keys ]] && continue
    grep -q "PRIVATE KEY" "$key" 2>/dev/null || continue
    ssh-keygen -y -P "" -f "$key" &>/dev/null && ssh-add "$key" 2>/dev/null
done

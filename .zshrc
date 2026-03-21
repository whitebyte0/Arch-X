# ── Shell options ────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

setopt AUTO_CD              # type a directory name to cd into it
setopt AUTO_PUSHD           # cd pushes onto directory stack
setopt PUSHD_IGNORE_DUPS    # no duplicates in dir stack
setopt PUSHD_SILENT         # don't print stack after pushd
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell

# ── Completion ───────────────────────────────────────
autoload -Uz compinit && compinit
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
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND='fd --type f --hidden --exclude .git'
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

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

# ── SSH management ───────────────────────────────────

# Interactive SSH host picker (uses fzf + ~/.ssh/config)
s() {
    local host
    host=$(awk '
        /^Host / && !/\*/ {
            name = $2
            user = ""; ip = ""; port = ""
        }
        /HostName/    { ip   = $2 }
        /User/        { user = $2 }
        /Port/        { port = $2 }
        /^$/ || /^Host / {
            if (name != "" && ip != "") {
                if (port == "") port = "22"
                printf "%-20s  %s@%s:%s\n", name, user, ip, port
            }
            if (/^Host / && !/\*/) { name = $2; user = ""; ip = ""; port = "" }
            else { name = "" }
        }
        END {
            if (name != "" && ip != "") {
                if (port == "") port = "22"
                printf "%-20s  %s@%s:%s\n", name, user, ip, port
            }
        }
    ' ~/.ssh/config | fzf --header="Select SSH host" --ansi | awk '{print $1}')

    [[ -n "$host" ]] && ssh "$host"
}

# Generate SSH key and deploy to remote host in one command
# Usage: ssh-deploy-key <label> <user> <ip> [port]
ssh-deploy-key() {
    if [[ $# -lt 3 ]]; then
        echo "Usage: ssh-deploy-key <label> <user> <ip> [port]"
        echo "  label  — name for the key and ssh config entry"
        echo "  user   — remote username"
        echo "  ip     — remote host IP or domain"
        echo "  port   — SSH port (default: 22)"
        echo ""
        echo "Example: ssh-deploy-key prod-api root 38.242.227.121"
        return 1
    fi

    local label=$1 user=$2 ip=$3 port=${4:-22}
    local keyfile="$HOME/.ssh/$label"

    # check if key already exists
    if [[ -f "$keyfile" ]]; then
        echo "Key $keyfile already exists. Deploy existing key? [y/N]"
        read -r reply
        [[ "$reply" != [yY] ]] && return 1
    else
        echo "Generating SSH key: $keyfile"
        ssh-keygen -t ed25519 -f "$keyfile" -N "" -C "$label"
    fi

    # deploy key to remote host (will prompt for password)
    echo "Deploying key to $user@$ip:$port ..."
    ssh-copy-id -i "$keyfile.pub" -p "$port" "$user@$ip"

    if [[ $? -ne 0 ]]; then
        echo "Failed to deploy key."
        return 1
    fi

    # add to ssh config if not already there
    if ! grep -q "^Host $label$" ~/.ssh/config 2>/dev/null; then
        printf '\nHost %s\n    HostName %s\n    User %s\n    Port %s\n    IdentityFile %s\n' \
            "$label" "$ip" "$user" "$port" "$keyfile" >> ~/.ssh/config
        echo "Added '$label' to ~/.ssh/config"
    fi

    echo "Done! Connect with: ssh $label"
}

# Mount remote filesystem via SSH (uses ~/.ssh/config hosts)
# Usage: mount-ssh <host> [remote-path]
mount-ssh() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: mount-ssh <host> [remote-path]"
        echo "  host        — label from ~/.ssh/config"
        echo "  remote-path — path on remote (default: /)"
        echo ""
        echo "Example: mount-ssh prod-api"
        echo "         mount-ssh prod-api /var/log"
        echo ""
        echo "Mounted hosts:"
        mount -t fuse.sshfs 2>/dev/null | awk '{print "  " $3}'
        return 1
    fi

    local host=$1 remote=${2:-/}
    local mountpoint="$HOME/mnt/$host"

    if mountpoint -q "$mountpoint" 2>/dev/null; then
        echo "Already mounted at $mountpoint"
        yazi "$mountpoint"
        return 0
    fi

    mkdir -p "$mountpoint"
    sshfs "${host}:${remote}" "$mountpoint" \
        -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
        -o follow_symlinks

    if [[ $? -eq 0 ]]; then
        echo "Mounted ${host}:${remote} → $mountpoint"
        yazi "$mountpoint"
    else
        echo "Failed to mount $host"
        rmdir "$mountpoint" 2>/dev/null
        return 1
    fi
}

# Unmount remote filesystem
# Usage: umount-ssh <host>   or   umount-ssh --all
umount-ssh() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: umount-ssh <host>"
        echo "       umount-ssh --all"
        echo ""
        echo "Mounted hosts:"
        local has_mounts=false
        for dir in "$HOME"/mnt/*(N/); do
            if mountpoint -q "$dir" 2>/dev/null; then
                echo "  $(basename $dir)"
                has_mounts=true
            fi
        done
        $has_mounts || echo "  (none)"
        return 1
    fi

    if [[ "$1" == "--all" ]]; then
        for dir in "$HOME"/mnt/*(N/); do
            if mountpoint -q "$dir" 2>/dev/null; then
                fusermount -u "$dir" && rmdir "$dir" 2>/dev/null
                echo "Unmounted $(basename $dir)"
            fi
        done
        return 0
    fi

    local mountpoint="$HOME/mnt/$1"
    if mountpoint -q "$mountpoint" 2>/dev/null; then
        fusermount -u "$mountpoint" && rmdir "$mountpoint" 2>/dev/null
        echo "Unmounted $1"
    else
        echo "$1 is not mounted"
    fi
}

# ── Autosuggestions color ────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#444444"

# ── Syntax highlighting (must be last) ──────────────
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(zoxide init zsh)"        # z <partial-dir> to jump
alias cat='bat --paging=never'   # syntax-highlighted cat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

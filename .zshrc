export PATH=/home/yoske/.local/bin:/usr/local/bin:$PATH
source $HOME/.zplug/init.zsh

zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions", defer:2
zplug "zsh-users/zsh-completions", defer:2

# Install plugins if there are plugins that have not been installed
if ! zplug check; then
    printf "Install zplug plugins? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
# zplug load --verbose
zplug load

# emacs-style keybinding
bindkey -e

if test -d "/opt/homebrew"; then
  export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
fi

if [[ "$OSTYPE" == "linux"* ]] && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

if command -v gdircolors >/dev/null 2>&1; then
  alias dircolors='gdircolors'
fi

if command -v kubecolor >/dev/null 2>&1; then
  alias kubectl='kubecolor'
fi
alias k='kubectl'

# history config
HISTSIZE=1000000
SAVEHIST=1000000
setopt hist_ignore_dups  # ignore duplication command history list
setopt hist_ignore_space # ignore when commands starts with space
setopt share_history     # share command history data


if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors "$HOME/.colorrc")"
fi
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -al'
alias ojt='g++ main.cpp && oj t'


export HOMEBREW_INSTALL_CLEANUP=1
export DOCKER_BUILDKIT=1
export FZF_LEGACY_KEYBINDINGS=0
export EDITOR=vim

# Go
export GOPATH=$HOME
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:$GOROOT/bin:$PATH

# Rust
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi

# node, ruby
if test -d "/opt/homebrew"; then
  . $(brew --prefix asdf)/libexec/asdf.sh
fi

# python
if command -v python3 >/dev/null 2>&1; then
  alias python='python3'
  USER_BASE_PATH=$(python -m site --user-base)
  export PATH=$PATH:$USER_BASE_PATH/bin
fi

# colordiff
if command -v colordiff >/dev/null 2>&1; then
  alias diff='colordiff'
fi

# aws completer; [WARNING]: this may slow loading .zshrc
# autoload bashcompinit && bashcompinit
# autoload -Uz compinit && compinit
# complete -C 'aws_completer' aws

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

function select-history() {
    BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
    CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

function select-gitrepo() {
    local src=$(ghq list | fzf --reverse --ansi --prompt="Git Repo >" \
      --preview "ls -lTp --color=auto $(ghq root)/{} | tail -n 10 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}' && bat --color=always --line-range :80 $(ghq root)/{}/README.*" \
      --preview-window right \
      )
    if [ -n "$src" ]; then
        BUFFER="cd $(ghq root)/$src"
        zle accept-line
    fi
    zle -R -c
}
zle -N select-gitrepo
bindkey '^g' select-gitrepo

# workaround
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi

alias watch='viddy'
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
export PATH="$HOME/.local/bin:$PATH"

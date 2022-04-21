export PATH=/usr/local/bin:$PATH
source ~/.zplug/init.zsh

zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions", defer:2
zplug "zsh-users/zsh-completions", defer:2

# Install plugins if there are plugins that have not been installed
if ! zplug check; then
    printf "Install? [y/N]: "
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

if test -x $(which gdircolors); then
  alias dircolors='gdircolors'
fi

if test -x $(which kubecolor); then
  alias kubectl='kubecolor'
fi
alias k='kubectl'


eval `dircolors ~/.colorrc`
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
if [ -f ~/.cargo/env ]; then
  source ~/.cargo/env
fi

# node, ruby
if test -d "/opt/homebrew"; then
  . $(brew --prefix asdf)/libexec/asdf.sh
fi

# python
if [ -x $(which python3) ]; then
  alias python='python3'
  USER_BASE_PATH=$(python -m site --user-base)
  export PATH=$PATH:$USER_BASE_PATH/bin
fi


# aws completer; [WARNING]: this may slow loading .zshrc
# autoload bashcompinit && bashcompinit
# autoload -Uz compinit && compinit
# complete -C 'aws_completer' aws

eval "$(direnv hook zsh)"
eval "$(starship init zsh)"

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
export PATH="/opt/homebrew/opt/go@1.17/bin:$PATH"

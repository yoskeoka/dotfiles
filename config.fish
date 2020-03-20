set PATH /usr/local/bin $PATH
status --is-interactive; and source (rbenv init -|psub)
set -x GOPATH $HOME
set -x GOBIN $GOPATH/bin
set -x PATH $GOBIN $PATH
#set -x GOROOT (go env GOROOT)

# rust
set -x PATH $HOME/.cargo/bin $PATH

# add python user base to PATH
set USER_BASE_PATH (python -m site --user-base)
set -x PATH $PATH {$USER_BASE_PATH}/bin

set -x EDITOR vim

# superior /usr/local/bin than /usr/bin
set -x PATH /usr/local/bin $PATH

# superior nodebrew
set -x PATH $HOME/.nodebrew/current/bin $PATH

# use gnu version unix commands
set -x PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
set -x MANPATH /usr/local/opt/coreutils/libexec/gnuman $MANPATH

alias awk='gawk'
alias factor='gfactor'
alias code.='code .'
alias open.='open .'

# coloring ls command
bass (dircolors ~/.colorrc)

function history-merge --on-event fish_preexec
    history --save
    history --merge
end

function peco_sync_select_history
    history-merge
    peco_select_history $argv
end

set -U FZF_LEGACY_KEYBINDINGS 0

function __ghq_cd_repository -d "Change local repository directory"
    ghq list --full-path | fzf --reverse --ansi | read -l repo_path
    if echo $repo_path | grep -E "/" >/dev/null ^/dev/null
        cd $repo_path
        commandline -f repaint
    end
end

function fish_user_key_bindings
    bind \cr 'peco_sync_select_history (commandline -b)'
    #   bind \cs peco_select_ghq_repository
    bind \cg '__ghq_cd_repository'
    if bind -M insert >/dev/null ^/dev/null
        bind -M insert \cg '__ghq_cd_repository'
    end
end

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f ~/.config/yarn/global/node_modules/tabtab/.completions/serverless.fish ]
and source ~/.config/yarn/global/node_modules/tabtab/.completions/serverless.fish
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f ~/.config/yarn/global/node_modules/tabtab/.completions/sls.fish ]
and source ~/.config/yarn/global/node_modules/tabtab/.completions/sls.fish

test -x (which aws_completer)
and complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

set -x DOCKER_BUILDKIT 1

[ -f ~/.google-cloud-sdk/path.fish.inc ]
and source ~/.google-cloud-sdk/path.fish.inc

set -x HOMEBREW_INSTALL_CLEANUP 1


# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[ -f ~/.config/yarn/global/node_modules/tabtab/.completions/slss.fish ]
and . ~/.config/yarn/global/node_modules/tabtab/.completions/slss.fish

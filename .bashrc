export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:/usr/local/go/bin:${PATH}


function ghql() {
  local selected_file=$(ghq list --full-path | peco --initial-filter "Fuzzy" --query "$LBUFFER")
  if [ -n "$selected_file" ]; then
    if [ -t 1 ]; then
      echo ${selected_file}
      cd ${selected_file}
      pwd
    fi
  fi
}

bind -x '"\201": ghql'
bind '"\C-g":"\201\C-m"'


#!/bin/bash

run_go() {
  if has "go"; then
    echo "Install go packages..."

    go install github.com/go-delve/delve/cmd/dlv@latest

    echo "$(tput setaf 2)Install go packages complete. ✔︎$(tput sgr0)"
  fi
}

#!/bin/bash

run_go() {
  if has "go"; then
    echo "Install go packages..."

    go get github.com/golang/lint/golint
    go get -u github.com/derekparker/delve/cmd/dlv
    go get -u golang.org/x/vgo

    echo "$(tput setaf 2)Install go packages complete. ✔︎$(tput sgr0)"
  fi
}

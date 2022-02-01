#!/bin/bash

run_npm() {

  if has "nodebrew"; then
    echo "Install node..."
    mkdir -p "$HOME/.nodebrew/src"
    nodebrew install stable
    nodebrew use stable
  fi

  if has "npm"; then
    echo "Install npm packages..."

    # npm i -g \
    #   @vue/cli

    echo "$(tput setaf 2)Install npm packages complete. ✔︎$(tput sgr0)"
  fi
}

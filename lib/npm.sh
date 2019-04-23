#!/bin/bash

run_npm() {
  if has "npm"; then
    echo "Install npm packages..."

    # npm i -g \
    #   @vue/cli

    echo "$(tput setaf 2)Install npm packages complete. ✔︎$(tput sgr0)"
  fi
}

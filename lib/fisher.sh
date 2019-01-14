#!/bin/bash

run_fisher() {
  if has "fish"; then
    echo "Install fisher packages..."

    fish ./lib/fisher.fish

    echo "$(tput setaf 2)Install fisher packages complete. ✔︎$(tput sgr0)"
  fi
}

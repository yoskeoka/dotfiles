#!/bin/bash

run_rust() {

  if has "rustup"; then
    echo "$(tput setaf 2)Already installed rustup ✔︎$(tput sgr0)"
  else
    echo "Installing rustup..."
    if [ ! -d $HOME/.cargo ]; then
      curl https://sh.rustup.rs -sSf | sh -s -- -y
    fi  
  fi

  if has "rustc"; then
  
  fi
}

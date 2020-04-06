#!/bin/bash

run_pip() {
  if has "pip"; then
    echo "$(tput setaf 2)Already installed pip ✔︎$(tput sgr0)"
  else
    echo "Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py --user
    rm get-pip.py
  fi

  if has "pip"; then
    echo "Install pip packages..."

    pip install awslogs --user --upgrade

    echo "$(tput setaf 2)Install pip packages complete. ✔︎$(tput sgr0)"
  fi
}

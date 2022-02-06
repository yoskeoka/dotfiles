#!/bin/bash

run_pip() {
  if has "pip3"; then
    echo "$(tput setaf 2)Already installed pip ✔︎$(tput sgr0)"
  else
    echo "Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py --user
    rm get-pip.py
  fi

  if has "pip3"; then
    echo "Install pip packages..."

    pip3 install --user \
      awslogs \
      online-judge-tools \
      --upgrade

    echo "$(tput setaf 2)Install pip packages complete. ✔︎$(tput sgr0)"
  fi
}

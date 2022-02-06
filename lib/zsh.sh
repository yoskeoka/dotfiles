#!/bin/bash

run_zsh() {
  if [ -f ~/.zplug/init.zsh ]; then
    echo "$(tput setaf 2)Already installed zplug ✔︎$(tput sgr0)"
  else
  echo "Install zplug..."

  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

  echo "$(tput setaf 2)Install zplug complete. ✔︎$(tput sgr0)"
  fi
}

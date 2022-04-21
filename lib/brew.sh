#!/bin/bash

run_brew() {
  if has "brew"; then
    echo "$(tput setaf 2)Already installed Homebrew ✔︎$(tput sgr0)"
  else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if has "brew"; then
    echo "Updating Homebrew..."
    brew update
    [[ $? ]] && echo "$(tput setaf 2)Update Homebrew complete. ✔︎$(tput sgr0)"

    echo "Installing missing Homebrew formulae..."

    brew bundle install --no-upgrade

    echo "$(tput setaf 2)Installed missing formulae ✔︎$(tput sgr0)"

    echo "Cleanup Homebrew..."
    brew cleanup
    echo "$(tput setaf 2)Cleanup Homebrew complete. ✔︎$(tput sgr0)"

    echo "Install asdf plugins..."
    echo "Install node..."
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf install nodejs latest
    asdf global nodejs latest
    echo "Install ruby..."
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
    asdf install ruby latest
    asdf global ruby latest
    echo "$(tput setaf 2)Install asdf plugins complete. ✔︎$(tput sgr0)"
  fi

  if has "fzf"; then
    $(brew --prefix)/opt/fzf/install --completion --no-key-bindings --no-update-rc
  fi
}

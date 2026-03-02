#!/bin/bash

run_asdf() {
  if has "asdf"; then
    echo "$(tput setaf 2)Already installed asdf ✔︎$(tput sgr0)"
  else
    if has "brew"; then
      echo "Installing asdf with Homebrew..."
      brew install asdf
    else
      echo "$(tput setaf 1)brew not found; skipping asdf install$(tput sgr0)"
    fi
  fi

  if [ -f "$HOME/.asdf/asdf.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.asdf/asdf.sh"
  elif has "brew"; then
    # shellcheck disable=SC1090
    . "$(brew --prefix asdf)/libexec/asdf.sh" 2>/dev/null
  fi

  if has "asdf"; then
    echo "Install asdf plugins..."
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git >/dev/null 2>&1 || true
    asdf install nodejs latest
    asdf global nodejs latest
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git >/dev/null 2>&1 || true
    asdf install ruby latest
    asdf global ruby latest
    echo "$(tput setaf 2)Install asdf plugins complete. ✔︎$(tput sgr0)"
  else
    echo "$(tput setaf 1)asdf not available in this shell; skipping plugins$(tput sgr0)"
  fi
}

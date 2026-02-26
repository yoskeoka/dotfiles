#!/bin/bash

run_apt() {
  if ! has "apt-get"; then
    echo "$(tput setaf 1)apt-get not found; skipping package install$(tput sgr0)"
    return
  fi

  local SUDO=""
  if has "sudo"; then
    SUDO="sudo"
  fi

  echo "Updating apt..."
  $SUDO apt-get update -y

  echo "Installing base packages..."
  $SUDO apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    libffi-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libyaml-dev \
    lsb-release \
    unzip \
    zip \
    zlib1g-dev \
    zsh

  echo "$(tput setaf 2)Installed base packages ✔︎$(tput sgr0)"
}

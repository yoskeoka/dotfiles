#!/bin/bash

set -e
OS="$(uname -s)"
DOT_DIRECTORY="${HOME}/dotfiles"
DOT_TARBALL="https://github.com/yoskeoka/dotfiles/tarball/master"
REMOTE_URL="https://github.com/yoskeoka/dotfiles.git"

has() {
  type "$1" > /dev/null 2>&1
}

usage() {
  name=`basename $0`
  cat <<EOF
Usage:
  $name [arguments] [command]
Commands:
  deploy [-f]
  initialize
  update
Arguments:
  -f $(tput setaf 1)** warning **$(tput sgr0) Overwrite dotfiles.
  -h Print help (this message)
EOF
  exit 1
}

while getopts "fh" opt; do
  case ${opt} in
    f)
      OVERWRITE=true
      ;;
    h)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

# If the dotfiles directory missing, download and extract the dotfiles repository
if [ ! -d ${DOT_DIRECTORY} ]; then
  echo "Downloading dotfiles..."
  mkdir ${DOT_DIRECTORY}

  if has "git"; then
    git clone --depth 1 --recursive "${REMOTE_URL}" "${DOT_DIRECTORY}"
  else
    curl -fsSLo ${HOME}/dotfiles.tar.gz ${DOT_TARBALL}
    tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOT_DIRECTORY}
    rm -f ${HOME}/dotfiles.tar.gz
  fi

  echo $(tput setaf 2)Download dotfiles complete!. ✔︎$(tput sgr0)
fi

cd ${DOT_DIRECTORY}
source ./lib/brew.sh
source ./lib/zsh.sh
source ./lib/fisher.sh
source ./lib/pip.sh
source ./lib/go.sh
source ./lib/rust.sh
source ./lib/npm.sh
source ./lib/yarn.sh
source ./lib/gnu_gcc.sh

link_files() {
  for f in .??*
  do
    # If you have ignore files, add file/directory name here
    [[ ${f} = ".git" ]] && continue
    [[ ${f} = ".gitignore" ]] && continue
    [[ ${f} = ".editorconfig" ]] && continue

    # Force remove the file if it's already there
    [ -n "${OVERWRITE}" -a -e ${HOME}/${f} ] && rm -f ${HOME}/${f}
    if [ ! -e ${HOME}/${f} ]; then

      ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/${f}
    fi
  done

  link_arr=(
    # dotfiles/{$src} {$HOME}/{$dest}
    "config.fish .config/fish/config.fish"
    "starship.toml .config/starship.toml"
    "kitty.conf .config/kitty/kitty.conf"
    # ".hammerspoon .hammerspoon"
  )
  for link in "${link_arr[@]}"
  do
    IFS=' ' read -r src dest <<< $link
    echo "$src -> $dest"
    [ -n "${OVERWRITE}" -a -e ${HOME}/${dest} ] && rm -f ${HOME}/${dest}
    mkdir -p $(dirname ${HOME}/${dest})
    ln -snfv ${DOT_DIRECTORY}/${src} ${HOME}/${dest}
  done

  ## karabiner.json
  conf_dest=".config/karabiner/karabiner.json"
  conf_src="karabiner.json"

  [ -n "${OVERWRITE}" -a -e ${HOME}/${conf_dest} ] && rm -f ${HOME}/${conf_dest}
  mkdir -p $(dirname ${HOME}/${conf_dest})
  cp ${DOT_DIRECTORY}/${conf_src} ${HOME}/${conf_dest}

  # OS dependent
  case ${OSTYPE} in
  darwin*)
    mkdir -p ${HOME}/Library/Preferences
    ln -snfv ${DOT_DIRECTORY}/acc ${HOME}/Library/Preferences/atcoder-cli-nodejs
    ;;
  *)
    ;;
  esac

  echo $(tput setaf 2)Deploy dotfiles complete!. ✔︎$(tput sgr0)
}

initialize() {
  # ignore shell execution error temporarily
  set +e

  case ${OSTYPE} in
    darwin*)
      run_brew
      ;;
    *)
      echo $(tput setaf 1)Working only OSX$(tput sgr0)
      exit 1
      ;;
  esac

  run_zsh
  run_fisher
  run_pip
  run_go
  run_rust
  run_npm
  run_yarn
  run_gnu_gcc

  echo "$(tput setaf 2)Initialize complete!. ✔︎$(tput sgr0)"
}

update() {
  brew bundle dump -f
}

command=$1
[ $# -gt 0 ] && shift

case $command in
  deploy)
    link_files
    ;;
  init*)
    initialize
    ;;
  update)
    update
    ;;
  *)
    usage
    ;;
esac

exit 0

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
  deploy
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

# If missing, download and extract the dotfiles repository
if [ ! -d ${DOT_DIRECTORY} ]; then
  echo "Downloading dotfiles..."
  mkdir ${DOT_DIRECTORY}

  if has "git"; then
    git clone --recursive "${REMOTE_URL}" "${DOT_DIRECTORY}"
  else
    curl -fsSLo ${HOME}/dotfiles.tar.gz ${DOT_TARBALL}
    tar -zxf ${HOME}/dotfiles.tar.gz --strip-components 1 -C ${DOT_DIRECTORY}
    rm -f ${HOME}/dotfiles.tar.gz
  fi

  echo $(tput setaf 2)Download dotfiles complete!. ✔︎$(tput sgr0)
fi

cd ${DOT_DIRECTORY}
source ./lib/brew.sh
source ./lib/fisher.sh
source ./lib/pip.sh
source ./lib/go.sh
source ./lib/npm.sh
source ./lib/yarn.sh

link_files() {
  for f in .??*
  do
    # If you have ignore files, add file/directory name here
    [[ ${f} = ".git" ]] && continue
    [[ ${f} = ".gitignore" ]] && continue
    [[ ${f} = ".editorconfig" ]] && continue

    # Force remove the vim directory if it's already there
    [ -n "${OVERWRITE}" -a -e ${HOME}/${f} ] && rm -f ${HOME}/${f}
    if [ ! -e ${HOME}/${f} ]; then

      ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/${f}
    fi
  done

  ## config.fish
  conf_dest=".config/fish/config.fish"
  conf_src="config.fish"

  [ -n "${OVERWRITE}" -a -e ${HOME}/${conf_dest} ] && rm -f ${HOME}/${conf_dest}
  touch ${HOME}/${conf_dest}
  ln -snfv ${DOT_DIRECTORY}/${conf_src} ${HOME}/${conf_dest}

  ## karabiner.json
  conf_dest=".config/karabiner/karabiner.json"
  conf_src="karabiner.json"

  [ -n "${OVERWRITE}" -a -e ${HOME}/${conf_dest} ] && rm -f ${HOME}/${conf_dest}
  touch ${HOME}/${conf_dest}
  ln -snfv ${DOT_DIRECTORY}/${conf_src} ${HOME}/${conf_dest}

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

  run_fisher
  run_pip
  run_go
  run_npm
  run_yarn

  if [ ! -d $HOME/.cargo ]; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  fi

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

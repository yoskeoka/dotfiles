#!/bin/bash

run_yarn() {
  if has "yarn"; then
    echo "Install yarn packages..."

# TODO: `yarn global list --depth=0`
    yarn global add \
                nodemon \
                @vue/cli \
                vuepress \
                gtop \
                ts-node

    echo "$(tput setaf 2)Install yarn packages complete. ✔︎$(tput sgr0)"
  fi
}

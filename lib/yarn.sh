#!/bin/bash

run_yarn() {
  if has "yarn"; then
    echo "Install yarn packages..."

    yarn global add \
                nodemon \
                @vue/cli \
                vuepress \
                newman \
                gtop \
                cfn-lint \
                serverless

    echo "$(tput setaf 2)Install yarn packages complete. ✔︎$(tput sgr0)"
  fi
}

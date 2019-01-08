#!/bin/bash

run_yarn() {
  if has "yarn"; then
    echo "Install yarn packages..."

    yarn global add \
                nodemon \
                serverless

    echo "$(tput setaf 2)Install yarn packages complete. ✔︎$(tput sgr0)"
  fi
}

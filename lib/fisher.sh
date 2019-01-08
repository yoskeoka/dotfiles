#!/bin/bash

run_fisher() {
  if has "fish"; then
      echo "Install fisher packages..."
      fish -c "
        fisher install \
        bobthefish \
        balias \
        bass \
        bd \
        peco \
        peco_select_ghq_repository
      "

    echo "$(tput setaf 2)Install fisher packages complete. ✔︎$(tput sgr0)"
  fi
}

#!/bin/bash

# find /opt/homebrew -name "stdc++.h"
# output example: /opt/homebrew/Cellar/gcc/11.2.0_3/include/c++/11/aarch64-apple-darwin21/bits/stdc++.h

run_gnu_gcc() {
  if has "brew"; then
    echo "Setup GNU gcc environment..."

    if [ ! -f /usr/local/bin/gcc ]; then

      gcc_full_ver=$(brew info gcc --json | jq -r '.[].linked_keg')
      echo "gnu gcc --version: $gcc_full_ver" 
      gcc_major_ver=$(echo $gcc_full_ver | cut -d'.' -f1)
      echo "gnu gcc major version: $gcc_major_ver"

      sudo ln -snfv $(brew --prefix)/bin/gcc-${gcc_major_ver} /usr/local/bin/gcc
      sudo ln -snfv $(brew --prefix)/bin/g++-${gcc_major_ver} /usr/local/bin/g++
      
      # to activate apple clang, 
      # $ export PATH="/usr/bin:$PATH"
      # or 
      # $ sudo unlink /usr/local/bin/gcc
      # $ sudo unlink /usr/local/bin/g++
    fi

    find $(brew --prefix) -name "stdc++.h" | read bits_stdcpp

    if [ ! -z $bits_stdcpp ]; then
      mkdir -p /usr/local/include
      ln -s $bits_dir /usr/local/include/bits/stdc++.h
    fi

    echo "$(tput setaf 2)Setup GNU gcc environment complete. ✔︎$(tput sgr0)"
  fi
}

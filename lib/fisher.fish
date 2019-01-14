#!/usr/local/bin/fish

# https://github.com/jorgebucaran/fisher
if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end

if functions -q fisher
  fisher install \
    bobthefish \
    balias \
    bass \
    bd \
    peco \
    peco_select_ghq_repository
end

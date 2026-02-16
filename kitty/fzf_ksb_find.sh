#!/usr/bin/env bash

show_context() {
    local n=$1
    local height=$FZF_PREVIEW_LINES

    ((height > total_lines)) && height=$total_lines

    local start=$((n - height / 2))
    local end=$((start + height))

    if ((start < 1)); then
        start=1
        end=$height
    elif ((end > total_lines)); then
        end=$total_lines
        start=$((end - height + 1))
        ((start < 1)) && start=1
    fi

    bat --color always --decorations never \
        --line-range $start:$end \
        --highlight-line $((n + 1)) \
        "$stdin"
}

stdin=$(mktemp)
cat > "$stdin"

total_lines=$(( $(wc -l < "$stdin") + 1 ))

export stdin
export total_lines
export -f show_context

export SHELL=bash

fzf --ansi \
    --no-sort --tac \
    --exact -i \
    --preview 'show_context {n}' \
    --preview-window border-none \
    --preview-window noinfo \
    < "$stdin"

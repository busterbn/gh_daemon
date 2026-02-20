#!/usr/bin/env bash
# gh_daemon - daily contribution generator
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/src"

COMMIT_MESSAGES=(
    "refactor: simplify internal logic"
    "chore: update constants"
    "fix: correct edge case in computation"
    "perf: optimize loop performance"
    "style: clean up formatting"
    "chore: bump build number"
    "refactor: rename internal variable"
    "fix: adjust threshold value"
    "perf: reduce unnecessary allocations"
    "chore: update seed values"
    "refactor: extract helper function logic"
    "fix: handle boundary condition"
    "style: normalize whitespace"
    "chore: tweak configuration defaults"
    "perf: cache intermediate results"
)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Mutate a single file by tweaking a random integer literal found in it
mutate_file() {
    local file="$1"

    # Find lines containing standalone integer literals (not in includes/imports)
    # Pick one at random and change the number slightly
    local line_numbers
    line_numbers=$(grep -n '[^a-zA-Z_"][0-9]\{1,4\}[^a-zA-Z_"x]' "$file" \
        | grep -v '#include\|#define\|import\|from\|VERSION' \
        | cut -d: -f1 || true)

    if [[ -z "$line_numbers" ]]; then
        # Fallback: append a comment with a timestamp
        echo "// updated: $(date +%s)" >> "$file"
        return
    fi

    # Pick a random line from the candidates
    local count
    count=$(echo "$line_numbers" | wc -l)
    local pick=$(( (RANDOM % count) + 1 ))
    local target_line
    target_line=$(echo "$line_numbers" | sed -n "${pick}p")

    # Read the line, find the first integer, and tweak it
    local original
    original=$(sed -n "${target_line}p" "$file")

    # Extract first number on the line and adjust it by -2..+2
    local number
    number=$(echo "$original" | grep -oP '\d+' | head -1)
    if [[ -n "$number" ]]; then
        local delta=$(( (RANDOM % 5) - 2 ))
        [[ $delta -eq 0 ]] && delta=1
        local new_number=$(( number + delta ))
        [[ $new_number -lt 0 ]] && new_number=0

        # Replace only the first occurrence on that line
        local escaped_original
        escaped_original=$(echo "$original" | sed 's/[&/\]/\\&/g')
        local new_line
        new_line=$(echo "$original" | sed "s/$number/$new_number/")
        local escaped_new
        escaped_new=$(echo "$new_line" | sed 's/[&/\]/\\&/g')

        sed -i "${target_line}s/.*/$escaped_new/" "$file"
    fi
}

do_round() {
    local round_num="$1"
    log "Round $round_num: mutating source files"

    # Mutate each source file
    for f in "$SRC_DIR"/*; do
        [[ -f "$f" ]] && mutate_file "$f"
    done

    # Pick a random commit message
    local msg_idx=$(( RANDOM % ${#COMMIT_MESSAGES[@]} ))
    local msg="${COMMIT_MESSAGES[$msg_idx]}"

    cd "$REPO_DIR"
    git add -A src/
    git commit -m "$msg" --allow-empty
    git push origin main

    log "Round $round_num: pushed with message '$msg'"
}

main() {
    log "gh_daemon starting"

    local n=$(( RANDOM % 10 ))
    log "Random number: $n"

    if [[ $n -eq 0 ]]; then
        log "Got 0 - doing nothing today"
        exit 0
    fi

    log "Will perform $n commit(s)"

    for (( i = 1; i <= n; i++ )); do
        do_round "$i"
        # Small delay between pushes so timestamps differ
        if [[ $i -lt $n ]]; then
            sleep $(( (RANDOM % 30) + 5 ))
        fi
    done

    log "gh_daemon finished - $n commit(s) pushed"
}

main "$@"

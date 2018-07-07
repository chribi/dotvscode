#!/bin/bash

# Check if running on windows (cygwin not tested).
if [[ "$(uname)" =~ "MINGW" || "$(uname)" =~ "CYGWIN" ]]; then
    settings_path="$APPDATA/Code/User/settings.json"
else
    settings_path="$HOME/.config/Code/User/settings.json"
fi

# Install an extension, given by its full name.
function install-extension() {
    if [[ -z $1 ]]; then return; fi
    code --install-extension $1
}

# Install multiple extensions listed in a file.
# Each non-empty line that does not start with a '#' is interpreted as extension.
# Warning: File has to end with a newline, otherwise last line is ignored by 'read'!
function install-extensions-from-file() {
    if [[ ! -e "$1" ]]; then return; fi

    while read -r line; do
        install-extension "$line"
    done < <(sed '/^[[:blank:]]*$/d; /^[[:blank:]]*#/d' "$1")
}

# Path to the 'json' utility (from https://github.com/trentm/json)
json_path="./tmp/json.js"

# Fetch json tool from github and place at $json_path
function setup-json-tool() {
    if [[ ! -e "$json_path" ]]; then
        url="https://github.com/trentm/json/raw/master/lib/json.js"
        echo "Download '$url' to '$json_path'"
        mkdir -p "$(dirname "$json_path")"
        curl -L $url > $json_path
    fi
}

# Use the json tool to merge $1 with $2 (second file wins), write output to $3
function json-merge() {
    cat "$1" "$2" | node "$json_path" --deep-merge > $3
}

# Merge the given json file into the settings.json at $settings_path.
# When merge_mode is 'prefer-newer', existing settings will be overwritten, otherwise they are preserved.
function merge-settings() {
    if [[ ! -e "$1" ]]; then return; fi

    echo "Merge '$1' into settings.json"
    tmp_file="./tmp/merged.json" # Merge to temporary file, in case of errors
    if [[ $merge_mode = "prefer-newer" ]]; then
        json-merge "$settings_path" "$1" "$tmp_file"
    else
        json-merge "$1" "$settings_path" "$tmp_file"
    fi

    if [[ $? -ne 0 ]]; then
        echo "Error merging file, abort."
        exit 1
    fi

    cp "$tmp_file" "$settings_path"
}

# Install plugins and settings belonging to a group.
function install-group() {
    install-extensions-from-file "./config/$1-extensions.txt"
    merge-settings "./config/$1-settings.json"
}

# List groups in 'config'
function list-groups() {
    ls config | sed 's/-[a-zA-Z.]*$//' | uniq
}

# Write empty settings.json if not existing.  Create backup otherwise.
function init-or-backup-settings() {
    if [[ ! -e "$settings_path" ]]; then
        echo "Write empty settings to '$settings_path'"
        echo "{ }" > "$settings_path"
    else
        backup_path="./tmp/settings.backup.json"
        echo "Create backup of '$settings_path' at $backup_path"
        cp "$settings_path" "$backup_path"
    fi
}

# Parse command line options.
function parse-opts() {
    groups=()
    merge_mode="prefer-older"
    all_groups="false"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -l | --list )
                list-groups
                exit 1
                ;;
            -n | --prefer-newer )
                merge_mode="prefer-newer"
                shift
                ;;
            -a | --all )
                all_groups="true"
                shift
                ;;
            -* )
                echo "Unknown argument: '$1'"
                exit 1
                ;;
            * )
                groups+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$all_groups" = "true" ]]; then
        groups=($(list-groups))
    fi
}

function main() {
    parse-opts $@
    if [[ "${#groups[@]}" -eq 0 ]]; then
        echo "No groups specified.  Use '$0 --all' to install everything."
        return
    fi
    setup-json-tool
    init-or-backup-settings

    for group in "${groups[@]}"; do
        install-group "$group"
    done
}

main $@

#!/bin/bash
# Here-string
read -r here_val <<< "here_string_value"
export BASHISM_HERE="$here_val"

# Process substitution
read -r proc_val < <(echo "proc_sub_value")
export BASHISM_PROC="$proc_val"

# [[ ]] test — literal string intentional; exercises =~ operator
# shellcheck disable=SC2050
if [[ "hello" =~ ^hel ]]; then
    export BASHISM_REGEX="regex_ok"
fi

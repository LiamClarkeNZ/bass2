#!/bin/bash
# shellcheck disable=SC2034  # colors is intentionally unused; fixture tests declare -A syntax
declare -A colors
colors[red]="#ff0000"
colors[green]="#00ff00"
colors[blue]="#0000ff"
export ASSOC_SENTINEL="assoc_ok"

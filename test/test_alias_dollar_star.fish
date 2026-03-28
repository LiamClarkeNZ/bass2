# Test that bash aliases with $* are converted to $argv for fish.
# Issue #91: $* is not supported in fish.

source (dirname (status -f))/../functions/bass.fish

bass source (dirname (status -f))/fixtures/alias_dollar_star.sh
set -l bass_status $status

if test $bass_status -ne 0
    echo (set_color red)"failed: bass exited with status $bass_status"(set_color normal)
    exit 1
end

# The alias should exist as a function (fish implements aliases as functions)
if not functions -q lstar
    echo (set_color red)"failed: alias lstar was not created"(set_color normal)
    exit 1
end

# Verify the alias body contains $argv, not $*
set -l defn (functions lstar)
if string match -q -- '*$\**' "$defn"
    echo (set_color red)"failed: alias body still contains \$*"(set_color normal)
    echo "Definition: $defn"
    exit 1
end

# The alias should be callable without errors
lstar hello >/dev/null 2>&1
set -l alias_status $status

if test $alias_status -ne 0
    echo (set_color red)"failed: alias lstar returned status $alias_status"(set_color normal)
    exit 1
end

echo (set_color green)"Success: alias with \$* works in fish"(set_color normal)

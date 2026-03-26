source (dirname (status -f))/../functions/bass.fish

bass source (dirname (status -f))/fixtures/newline_export.sh
set -l bass_status $status

if test $bass_status -ne 0
    echo (set_color red)"failed: bass exited with status $bass_status"(set_color normal)
    exit 1
end

# Check the variable contains actual newlines, not literal \n
set -l line_count (echo "$MULTILINE_VAR" | wc -l | string trim)
if test "$line_count" -ne 3
    echo (set_color red)"failed: expected 3 lines, got $line_count"(set_color normal)
    echo "Value: $MULTILINE_VAR"
    exit 1
end

echo (set_color green)"Success: multiline env var preserved"(set_color normal)
set -e MULTILINE_VAR

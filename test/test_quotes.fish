source (dirname (status -f))/../functions/bass.fish

bass export JSON_VAR='{"key": "value"}'
set -l bass_status $status

if test $bass_status -ne 0
    echo (set_color red)"failed: bass exited with status $bass_status"(set_color normal)
    exit 1
end

if test "$JSON_VAR" != '{"key": "value"}'
    echo (set_color red)"failed: expected '{\"key\": \"value\"}', got '$JSON_VAR'"(set_color normal)
    exit 1
end

echo (set_color green)"Success: quotes preserved in env var"(set_color normal)
set -e JSON_VAR

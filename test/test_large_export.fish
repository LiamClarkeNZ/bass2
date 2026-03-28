# Test that bass handles large numbers of exports without hanging.
# Issue #77: pipe buffer overflow caused deadlock.

source (dirname (status -f))/../functions/bass.fish

# This script exports ~20KB of data, exceeding the 16KB macOS pipe buffer.
# With the old pipe-based approach, this would hang indefinitely.
bass source (dirname (status -f))/fixtures/large_export.sh
set -l bass_status $status

if test $bass_status -ne 0
    echo (set_color red)"failed: bass exited with status $bass_status"(set_color normal)
    exit 1
end

if test "$LARGE_EXPORT_SENTINEL" != "done"
    echo (set_color red)"failed: LARGE_EXPORT_SENTINEL not set"(set_color normal)
    exit 1
end

# Clean up all the test variables
for i in (seq 1 200)
    set -e "LARGE_VAR_$i"
end
set -e LARGE_EXPORT_SENTINEL

echo (set_color green)"Success: large export completed without hanging"(set_color normal)

# Test that bass with absolute paths doesn't take unreasonably long.
# Issue #92: forward slashes in paths caused extreme slowdown.

source (dirname (status -f))/../functions/bass.fish

# Create a temp script in a nested directory (many slashes)
set -l tmpdir (mktemp -d)
mkdir -p "$tmpdir/a/b/c/d/e/f"
echo 'export SLASH_TEST=ok' > "$tmpdir/a/b/c/d/e/f/test.sh"

# This should complete in well under 5 seconds
set -l start (date +%s)
bass source "$tmpdir/a/b/c/d/e/f/test.sh"
set -l elapsed (math (date +%s) - $start)

# Clean up
rm -rf $tmpdir

if test "$SLASH_TEST" != "ok"
    echo (set_color red)"failed: SLASH_TEST not set"(set_color normal)
    exit 1
end

if test $elapsed -gt 5
    echo (set_color red)"failed: took $elapsed seconds (expected < 5)"(set_color normal)
    exit 1
end

echo (set_color green)"Success: slashed path completed in $elapsed seconds"(set_color normal)
set -e SLASH_TEST

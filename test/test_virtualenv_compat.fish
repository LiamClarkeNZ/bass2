# Test that bass works when a virtualenv is active.
# Issue #102: -sS flag suppresses site packages, breaking virtualenv.

source (dirname (status -f))/../functions/bass.fish

# Create a minimal virtualenv
set -l tmpdir (mktemp -d)
python3 -m venv "$tmpdir/venv"

# Activate the virtualenv by setting the relevant env vars
set -gx VIRTUAL_ENV "$tmpdir/venv"
set -gx PATH "$tmpdir/venv/bin" $PATH

# Try to use bass — this should not error
bass export BASS_TEST_VAR=virtualenv_works 2>/tmp/bass_venv_stderr
set -l bass_status $status

# Clean up
set -e VIRTUAL_ENV
set -e BASS_TEST_VAR
rm -rf $tmpdir

if test $bass_status -ne 0
    echo (set_color red)"failed: bass broke under virtualenv (status $bass_status)"(set_color normal)
    cat /tmp/bass_venv_stderr
    exit 1
end

echo (set_color green)"Success: bass works under virtualenv"(set_color normal)

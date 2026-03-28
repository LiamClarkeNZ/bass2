#!/usr/bin/env fish
# Smoke tests for bass2 — exercises real-world bash tools and tricky bashisms.

set -g test_pass 0
set -g test_fail 0
set -g test_failures

# Resolve paths
set -g smoke_dir (dirname (status -f))
set -g bass_dir (dirname (dirname $smoke_dir))

source $bass_dir/functions/bass.fish

function run_test --argument-names name
    set -g current_test $name
    echo -n "  $name ... "
end

function assert_eq --argument-names actual expected label
    if test "$actual" = "$expected"
        return 0
    end
    echo (set_color red)"FAIL"(set_color normal)
    echo "    $label: expected '$expected', got '$actual'"
    set -g test_fail (math $test_fail + 1)
    set -g -a test_failures $current_test
    return 1
end

function pass
    echo (set_color green)"ok"(set_color normal)
    set -g test_pass (math $test_pass + 1)
end

function fail_test --argument-names msg
    echo (set_color red)"FAIL"(set_color normal)
    echo "    $msg"
    set -g test_fail (math $test_fail + 1)
    set -g -a test_failures $current_test
end

# ── SDKMAN ──────────────────────────────────────────────

run_test "sdkman: source init and run sdk version"
bass source "$HOME/.sdkman/bin/sdkman-init.sh"
if test $status -ne 0
    fail_test "bass failed to source sdkman-init.sh"
else
    set -l sdk_out (bass 'sdk version' 2>&1)
    if test $status -ne 0
        fail_test "sdk version failed: $sdk_out"
    else if not string match -q '*SDKMAN*' "$sdk_out"
        fail_test "sdk version output unexpected: $sdk_out"
    else
        pass
    end
end

# ── nvm ─────────────────────────────────────────────────

run_test "nvm: source nvm.sh and run nvm --version"
set -l nvm_dir "$HOME/.nvm"
bass source "$nvm_dir/nvm.sh"
if test $status -ne 0
    fail_test "bass failed to source nvm.sh"
else
    set -l nvm_out (bass 'nvm --version' 2>&1)
    if test $status -ne 0
        fail_test "nvm --version failed: $nvm_out"
    else if not string match -q -r '^\d+\.\d+' "$nvm_out"
        fail_test "nvm --version output unexpected: $nvm_out"
    else
        pass
    end
end

# ── Compound exports ────────────────────────────────────

run_test "compound exports: export A=1 B=2 C=3"
bass source $smoke_dir/fixtures/compound_exports.sh
if test $status -ne 0
    fail_test "bass failed to source compound_exports.sh"
else
    set -l ok 1
    assert_eq "$COMPOUND_A" "alpha" "COMPOUND_A"; or set ok 0
    assert_eq "$COMPOUND_B" "beta" "COMPOUND_B"; or set ok 0
    assert_eq "$COMPOUND_C" "gamma" "COMPOUND_C"; or set ok 0
    if test $ok -eq 1
        pass
    end
    set -e COMPOUND_A; set -e COMPOUND_B; set -e COMPOUND_C
end

# ── Source chains ───────────────────────────────────────

run_test "source chain: A sources B sources C"
bass source $smoke_dir/fixtures/source_chain_a.sh
if test $status -ne 0
    fail_test "bass failed to source source_chain_a.sh"
else
    set -l ok 1
    assert_eq "$CHAIN_A" "aaa" "CHAIN_A"; or set ok 0
    assert_eq "$CHAIN_B" "bbb" "CHAIN_B"; or set ok 0
    assert_eq "$CHAIN_C" "ccc" "CHAIN_C"; or set ok 0
    if test $ok -eq 1
        pass
    end
    set -e CHAIN_A; set -e CHAIN_B; set -e CHAIN_C
end

# ── Functions that modify env ───────────────────────────

run_test "function modifies env: exports var from function"
bass source $smoke_dir/fixtures/func_modifies_env.sh
if test $status -ne 0
    fail_test "bass failed to source func_modifies_env.sh"
else
    assert_eq "$FUNC_MODIFIED_VAR" "set_by_function" "FUNC_MODIFIED_VAR"
    and pass
    set -e FUNC_MODIFIED_VAR
end

# ── Associative arrays ──────────────────────────────────

run_test "associative arrays: declare -A runs without error"
bass source $smoke_dir/fixtures/associative_array.sh
if test $status -ne 0
    fail_test "bass failed to source associative_array.sh"
else
    assert_eq "$ASSOC_SENTINEL" "assoc_ok" "ASSOC_SENTINEL"
    and pass
    set -e ASSOC_SENTINEL
end

# ── PATH manipulation ───────────────────────────────────

run_test "PATH manipulation: prepend and append"
set -l old_path $PATH
bass source $smoke_dir/fixtures/path_manipulation.sh
if test $status -ne 0
    fail_test "bass failed to source path_manipulation.sh"
else
    set -l ok 1
    if not contains /opt/smoke-prepend $PATH
        fail_test "/opt/smoke-prepend not in PATH"
        set ok 0
    end
    if not contains /opt/smoke-append $PATH
        fail_test "/opt/smoke-append not in PATH"
        set ok 0
    end
    if test $ok -eq 1
        pass
    end
    set -g -x PATH $old_path
end

# ── Bashisms ────────────────────────────────────────────

run_test "bashisms: here-string, process substitution, [[ regex ]]"
bass source $smoke_dir/fixtures/bashisms.sh
if test $status -ne 0
    fail_test "bass failed to source bashisms.sh"
else
    set -l ok 1
    assert_eq "$BASHISM_HERE" "here_string_value" "BASHISM_HERE"; or set ok 0
    assert_eq "$BASHISM_PROC" "proc_sub_value" "BASHISM_PROC"; or set ok 0
    assert_eq "$BASHISM_REGEX" "regex_ok" "BASHISM_REGEX"; or set ok 0
    if test $ok -eq 1
        pass
    end
    set -e BASHISM_HERE; set -e BASHISM_PROC; set -e BASHISM_REGEX
end

# ── Summary ─────────────────────────────────────────────

echo ""
set -l total (math $test_pass + $test_fail)
if test $test_fail -gt 0
    echo (set_color red)"$test_fail/$total tests failed:"(set_color normal)
    for f in $test_failures
        echo "  - $f"
    end
    exit 1
else
    echo (set_color green)"All $total smoke tests passed."(set_color normal)
end

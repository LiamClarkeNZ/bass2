source (dirname (status -f))/../functions/bass.fish

# Function capture requires bash 4+ (bash 3.2 on macOS outputs function bodies
# via declare -p, which confuses load_state before declare -F is processed)
set -l bash_major (bash -c 'echo ${BASH_VERSINFO[0]}')
if test "$bash_major" -lt 4
    echo (set_color yellow)"skip: function capture requires bash 4+ (found bash $bash_major)"(set_color normal)
    exit 0
end

# Create a temp bash script that defines a function
set -l tmpscript (mktemp)
printf 'my_test_func() { echo "function_works"; }\n' > $tmpscript

bass source $tmpscript
set -l bass_status $status

if test $bass_status -ne 0
    echo (set_color red)"failed: bass exited with status $bass_status"(set_color normal)
    rm $tmpscript
    exit 1
end

# The function should now be callable from fish
set -l output (my_test_func 2>&1)
set -l func_status $status

rm $tmpscript

if test $func_status -ne 0
    echo (set_color red)"failed: my_test_func returned status $func_status"(set_color normal)
    exit 1
end

if test "$output" != "function_works"
    echo (set_color red)"failed: expected 'function_works', got '$output'"(set_color normal)
    exit 1
end

echo (set_color green)"Success: bash function captured and callable from fish"(set_color normal)

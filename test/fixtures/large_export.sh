#!/bin/bash
# Generate a large number of exports to exceed pipe buffer (16KB on macOS).
# Each variable is ~100 bytes, 200 variables = ~20KB.
for i in $(seq 1 200); do
    export "LARGE_VAR_$i=$(printf 'x%.0s' $(seq 1 80))"
done
export LARGE_EXPORT_SENTINEL="done"

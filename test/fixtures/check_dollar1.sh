# If $1 is set, this script will print it — which would indicate a leak
if [ -n "$1" ]; then
    echo "LEAKED: \$1 = $1"
    exit 1
fi
echo "OK: \$1 is empty"

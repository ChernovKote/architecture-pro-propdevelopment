#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Checking insecure manifests ==="

for file in "$BASE_DIR"/insecure-manifests/*.yaml; do
    echo "Checking $(basename "$file")"

    if kubectl apply --dry-run=server -f "$file" >/dev/null 2>&1; then
        echo "FAIL: Insecure Pod was allowed"
        exit 1
    else
        echo "PASS: Insecure Pod was rejected"
    fi
done

echo
echo "=== Checking secure manifests ==="

for file in "$BASE_DIR"/secure-manifests/*.yaml; do
    echo "Checking $(basename "$file")"

    if kubectl apply --dry-run=server -f "$file"; then
        echo "PASS: Secure Pod was allowed"
    else
        echo "FAIL: Secure Pod was rejected"
        exit 1
    fi
done

echo
echo "All admission checks passed!"
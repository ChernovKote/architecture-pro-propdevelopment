#!/bin/bash
set -e

for ns in sales housing finance data; do
    kubectl create namespace "$ns" \
        --dry-run=client -o yaml | kubectl apply -f -
done
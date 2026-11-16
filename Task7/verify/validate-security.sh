#!/bin/bash
set -euo pipefail

echo "=== Pod Security Admission ==="

LEVEL=$(kubectl get namespace audit-zone \
    -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')

if [ "$LEVEL" = "restricted" ]; then
    echo "PASS: PodSecurity restricted enabled"
else
    echo "FAIL: PodSecurity restricted not enabled"
    exit 1
fi

echo
echo "=== Gatekeeper ==="

kubectl rollout status deployment/gatekeeper-controller-manager \
    -n gatekeeper-system --timeout=60s

echo
echo "=== Gatekeeper Constraints ==="

CONSTRAINTS=(
    "k8sblockprivileged/block-privileged"
    "k8sblockhostpath/block-hostpath"
    "k8srequirenonroot/require-nonroot"
    "k8srequirereadonlyfs/require-readonlyfs"
)

for constraint in "${CONSTRAINTS[@]}"; do
    ACTION=$(kubectl get "$constraint" \
        -o jsonpath='{.spec.enforcementAction}')

    if [ "$ACTION" = "deny" ]; then
        echo "PASS: $constraint (deny)"
    else
        echo "FAIL: $constraint"
        exit 1
    fi
done

echo
echo "All security configuration checks passed!"
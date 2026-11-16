#!/bin/bash
set -e

for ns in sales housing finance data; do

    kubectl create rolebinding analyst-binding \
        --role=viewer \
        --serviceaccount="$ns:analyst" \
        -n "$ns"

    kubectl create rolebinding developer-binding \
        --role=developer \
        --serviceaccount="$ns:developer" \
        -n "$ns"

    kubectl create rolebinding devops-binding \
        --role=namespace-admin \
        --serviceaccount="$ns:devops" \
        -n "$ns"

done
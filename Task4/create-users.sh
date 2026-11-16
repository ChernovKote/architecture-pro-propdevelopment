#!/bin/bash
set -e

for ns in sales housing finance data; do
    for user in analyst developer devops; do
        kubectl create serviceaccount "$user" -n "$ns"
    done
done
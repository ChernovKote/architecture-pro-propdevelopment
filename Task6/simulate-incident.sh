#!/bin/bash

kubectl create namespace secure-ops
kubectl config set-context --current --namespace=secure-ops

kubectl create serviceaccount monitoring

kubectl auth can-i get secrets \
  --as=system:serviceaccount:secure-ops:monitoring

kubectl get secrets -n kube-system \
  --as=system:serviceaccount:secure-ops:monitoring

kubectl run privileged-pod \
  --image=alpine \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "privileged",
        "image": "alpine",
        "command": ["sleep", "3600"],
        "securityContext": {"privileged": true}
      }]
    }
  }'

COREDNS=$(kubectl get pods -n kube-system \
  -o name | grep coredns | head -n 1)

kubectl exec -n kube-system "$COREDNS" -- cat /etc/resolv.conf

kubectl create rolebinding escalate-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=secure-ops:monitoring \
  -n secure-ops
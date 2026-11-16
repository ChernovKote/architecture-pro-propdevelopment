#!/bin/bash
set -e

for ns in sales housing finance data; do

    kubectl create role viewer \
        --verb=get,list,watch \
        --resource=pods,deployments,services,pods/log \
        -n "$ns"

    kubectl create role developer \
        --verb=get,list,watch,create,update,patch,delete \
        --resource=pods,deployments,services,configmaps \
        -n "$ns"

    kubectl create role namespace-admin \
        --verb=get,list,watch,create,update,patch,delete \
        --resource=pods,deployments,services,configmaps,secrets \
        -n "$ns"

done
#!/usr/bin/env bash

TAG="[$(basename -- "$0")]"

usage="Usage: COMPANY={VALUE} PROJECT={VALUE} USERID={VALUE} ./create-user.sh"

USERID=${USERID:=}
userid=$(echo ${USERID} | tr '[:upper:]' '[:lower:]')

PROJECT=${PROJECT:=}
project=$(echo ${PROJECT} | tr '[:upper:]' '[:lower:]')

COMPANY=${COMPANY:=}
company=$(echo ${COMPANY} | tr '[:upper:]' '[:lower:]')

if [ -z "$USERID" ] || [ -z "$PROJECT" ] || [ -z "${COMPANY}" ]; then
    echo ${usage}
    exit 1
fi

PREFIX="${company}_${project}_${userid}"

kubectl config use-context kops.${project}.${company}.k8s.local

echo -e ""
echo -e "${TAG} Deleting files: ${PREFIX}*"
rm -rf ${PREFIX}*;

echo -e ""
echo -e "${TAG} Deleting kuberntes csr: ${PREFIX}"
kubectl delete csr ${PREFIX}


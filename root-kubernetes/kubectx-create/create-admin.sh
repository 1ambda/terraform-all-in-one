#!/usr/bin/env bash

TAG="[$(basename -- "$0")]"

usage="Usage: COMPANY={VALUE} PROJECT={VALUE} USERID={VALUE} ./create-user.sh"

USERID=${USERID:=}
userid=$(echo ${USERID} | tr '[:upper:]' '[:lower:]')

PROJECT=${PROJECT:=}
project=$(echo ${PROJECT} | tr '[:upper:]' '[:lower:]')

COMPANY=${COMPANY:=}
company=$(echo ${COMPANY} | tr '[:upper:]' '[:lower:]')

if [ -z "USERID" ] || [ -z "$PROJECT" ] || [ -z "${COMPANY}" ]; then
    echo ${usage}
    exit 1
fi

GROUP="admin"
PREFIX="${company}_${project}_${userid}"

# changing kubectl context
echo -e "${TAG} Switching kubectl context"
kubectl config use-context kops.${project}.${company}.k8s.local

# apply admin group role
echo -e ""
echo -e "${TAG} Applying admin group role"
kubectl apply -f admin-roles.yaml

# listing existing csr
echo -e ""
echo -e "${TAG} Existing kubectl csr"
kubectl get csr

# creating cert
echo -e ""
echo -e "${TAG} Creating kubectl certification"
openssl genrsa -out ${PREFIX}.pem 2048 # create pem
openssl req -new -key ${PREFIX}.pem -out ${PREFIX}.csr -subj "/CN=${PREFIX}/O=${GROUP}" # create csr
cat csr.template.yaml | sed s/\$PREFIX/$PREFIX/ | sed s/\$ENCODED_CSR/$(cat ${PREFIX}.csr | base64 | tr -d '\n')/ # check csr
cat csr.template.yaml | sed s/\$PREFIX/$PREFIX/ | sed s/\$ENCODED_CSR/$(cat ${PREFIX}.csr | base64 | tr -d '\n')/ | kubectl create -f - # apply csr
kubectl certificate approve ${PREFIX} # approve the csr request
kubectl get csr ${PREFIX} -o jsonpath='{.status.certificate}' | base64 -D > ${PREFIX}.crt # generate crt

# generate register.sh
echo -e ""
echo -e "${TAG} Generating registration shell script"
namespace="default"
api_elb=$(kubectl cluster-info | head -n1 | awk '{ print $6 }' | tr -d '[:space:]' | sed "s,$(printf '\033')\\[[0-9;]*[a-zA-Z],,g")
register_sh="${PREFIX}_register.sh"
echo "kubectl config set-cluster ${PREFIX} --insecure-skip-tls-verify=true --server=${api_elb}" > ${register_sh}
echo "kubectl config set-credentials ${PREFIX} --client-certificate=${PREFIX}.crt --client-key=${PREFIX}.pem --embed-certs=true" >> ${register_sh}
echo "kubectl config set-context ${PREFIX} --cluster=${PREFIX} --user=${PREFIX} --namespace=${namespace}" >> ${register_sh}
echo "kubectl config use-context ${PREFIX}" >> ${register_sh}
echo "kubectl get pods" >> ${register_sh}
echo "kubectl get nodes" >> ${register_sh}
chmod +x ${register_sh}
zip -R ${PREFIX}.zip "${PREFIX}*"
rm -rf ${PREFIX}.crt
rm -rf ${PREFIX}.csr
rm -rf ${PREFIX}.pem
rm -rf ${PREFIX}_register.sh
cp ${PREFIX}.zip ../../

echo -e ""
echo -e "${TAG} Created files"
ls -al | grep ${PREFIX}

echo -e ""
echo -e "${TAG} If something is wrong execute these commands and try again."
echo -e ""
echo -e "\t COMPANY=${company} PROJECT=${project} USERID=${userid} ./cleanup-csr.sh"


#!/bin/bash
#
# Copyright IBM Corporation 2020
#  released under the terms of the Apache License 2.0
#  Example use only


if [[ $# != 2 ]]
  then
  echo "usage: mirrorOcpInstall.sh <pull_secret.json> <ocp_env_vars_file>"
  exit 4
fi

echo secret is $1
echo rel file is $2

source $2

echo release is  ${OCP_RELEASE}
echo arch is     ${ARCHITECTURE}

export DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"
echo digest is   $DIGEST

export DIGEST_ALGO="${DIGEST%%:*}"
echo digest algo $DIGEST_ALGO

export DIGEST_ENCODED="${DIGEST#*:}"
echo digest enco $DIGEST_ENCODED

export SIGNATURE_BASE64=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1" | base64 -w0 && echo)
echo signature   $SIGNATURE_BASE64


cat >checksum-${OCP_RELEASE}.update.confmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-image-${OCP_RELEASE}
  namespace: openshift-config-managed
  labels:
    release.openshift.io/verification-signatures: ""
binaryData:
  ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
EOF

oc adm release mirror -a $1 --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

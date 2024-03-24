#!/bin/bash
#
# Copyright IBM Corporation 2020
#  released under the terms of the Apache License 2.0
#  Example use only


if [[ $# != 1 ]]
  then
  echo "usage: cliUpgrade.sh <ocp_env_vars_file>"
  echo "note that this script expects internet access to pull the release info from redhat"
  exit 4
fi

echo rel file is $1

source $1

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


oc adm upgrade --allow-upgrade-with-warnings --allow-explicit-upgrade --to-image ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}@${DIGEST}

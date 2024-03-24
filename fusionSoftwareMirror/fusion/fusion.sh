#!/bin/bash
#
# Copyright IBM Corporation 2023
# Mirror the pacakages needed for the IBM Spectrum Fusion Operator
if [[ $# != 1 ]]; then
  echo "usage: fusion.sh <env_file>"
  exit 4
fi
echo env file used is $1
# Make ENV variables available to script at run time
source $1
# Make Sure Fusion Version is set correctly
if [ "${#FUSION_VERSION}" -le 3 ]; then
  printf "ERROR: Fusion Version $FUSION_VERSION is not supported, check the list of supported versions in your ENV file and try again.\nNote: All releases of Fusion must include the minor version suffix (e.g, 2.6 must be 2.6.0)\n"
  exit 1
fi
# Issue Skopeo Copy Commands
echo "Issuing Mirror Commands for Fusion"
sh ./versionsFusion/$FUSION_VERSION
echo "Fusion Mirror Completed"
# Copy template Fusion ICSP file
cp templates/icsps/fusion.yaml $POLICY_FILE
# Replace Registry in ICSP file
sed -i "s+\$TARGET_PATH+$TARGET_PATH+g" $POLICY_FILE
# Create the Registry API to capture the version of fusion we are using
PORT=$(echo $TARGET_PATH | awk 'match($0,/:([0-9]+)/) { print substr($0,RSTART,RLENGTH) }')
REGAPI="${TARGET_PATH/${PORT}/${PORT}'/v2'}"
# Curl down the version of fusion
readarray -t fusionVersionArray < <(curl -s --user "$REGUSER:$REGPASS" https://$REGAPI/isf-operator-software-catalog/tags/list | jq .tags[] | tr -d '"')
# Check if Fusion Version has been Mirrored
for version in "${fusionVersionArray[@]}"
do
  if [[ "$FUSION_VERSION" == "$version" ]]; then
    fusionVersion=$version
  fi
done
# Verify Fusion Version
if [ -z ${fusionVersion+x} ]; then
  echo ERROR: Fusion Version $FUSION_VERSION was not found at https://$REGAPI/isf-operator-software-catalog/tags/list
  exit 1
fi
# Copy template Fusion ICSP file
cp templates/catalogs/fusion.yaml $CATALOG_SOURCE
# Replace Registry in catalog source file
sed -i "s+<catalogsource>+${TARGET_PATH}/isf-operator-software-catalog:$fusionVersion+g" $CATALOG_SOURCE
# Completion Message
echo "Storage Fusion Script has completed"
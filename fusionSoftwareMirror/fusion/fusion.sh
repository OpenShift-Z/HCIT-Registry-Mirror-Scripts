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
# use skopeo to make sure our target tag exists in the registry
readarray -t fusionVersionArray < <(skopeo list-tags docker://$TARGET_PATH/isf-operator-software-catalog | jq .Tags[] | tr -d '"')
# Check if Fusion Version has been Mirrored
for version in "${fusionVersionArray[@]}"
do
  if [[ "$FUSION_VERSION" == "$version" ]]; then
    fusionVersion=$version
  fi
done
# Verify Fusion Version
if [ -z ${fusionVersion+x} ]; then
  echo ERROR: Fusion Version $FUSION_VERSION was not found at docker://$TARGET_PATH/isf-operator-software-catalog/tags/list
  exit 1
fi
# Copy template Fusion ICSP file
cp templates/catalogs/fusion.yaml $CATALOG_SOURCE
# Replace Registry in catalog source file
sed -i "s+<catalogsource>+${TARGET_PATH}/isf-operator-software-catalog:$fusionVersion+g" $CATALOG_SOURCE
# Completion Message
echo "Storage Fusion Script has completed"
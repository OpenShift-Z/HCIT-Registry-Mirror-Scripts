#!/bin/bash
#
# Copyright IBM Corporation 2023
# Mirror the pacakages needed for CNSA
if [[ $# != 1 ]]; then
    echo "usage: cnsa.sh <env_file>"
    exit 4
fi

echo env file used is $1
# Make ENV variables available to script at run time
source $1
# Issue Skopeo Copy Commands
echo "Issuing Mirror Commands for CNSA"
sh ./versionsCNSA/$FUSION_VERSION
echo "CNSA Mirror Completed"
# Define Apply Policy File Function
function applyNewPolicyFile {
   echo "Apply Policy file for CNSA"
   # Copy template CNSA ICSP file
   cp templates/icsps/cnsa.yaml $POLICY_FILE
   # Replace Registry in content source file
   sed -i "s+\$TARGET_PATH+$TARGET_PATH+g" $POLICY_FILE
   # Create the policy file
   oc create -f $POLICY_FILE
}
# Check Fusion ICSP ENV VAR is set
if [[ ! -z ${FUSION_ICSP+x} ]]
then  
   # Capture source being used by current Fusion ICSP file
   ICSP_SOURCE=$(oc get ImageContentSourcePolicy/$FUSION_ICSP -o json | jq '.spec.repositoryDigestMirrors[] | select(.source ==
   "icr.io/cpopen") | .source')
   # Check if a duplicate entry exists for our ICSP file 
   if [[ $ICSP_SOURCE == '"icr.io/cpopen"' ]]
   then
     # Set Index Variables
     REPO_INDEX=$(oc get ImageContentSourcePolicy/$FUSION_ICSP -o json | jq '.spec.repositoryDigestMirrors[] | select(.source == "icr.io/cpopen") | .mirrors | length')
     MIRROR_INDEX=$(oc get ImageContentSourcePolicy/$FUSION_ICSP -o json | jq '.spec.repositoryDigestMirrors | length')
     # Crate Temporary JSON file
     oc get ImageContentSourcePolicy/$FUSION_ICSP -o json > temp.json
     # Add New Mirror Repo
     jq --arg repo_i $REPO_INDEX --arg path $TARGET_PATH '(.spec.repositoryDigestMirrors[] | select(.source == "icr.io/cpopen")).mirrors[$repo_i|fromjson] |= $path' temp.json > update.json && mv update.json temp.json
     # Add New Mirror Statement
     jq --arg mirror_i $MIRROR_INDEX --arg path $TARGET_PATH '(.spec.repositoryDigestMirrors[$mirror_i|fromjson]) |= {"mirrors":[$path],"source":"cp.icr.io/cp/spectrum/scale"}' temp.json  > update.json && mv update.json temp.json
     PATCH=$(jq '.spec.repositoryDigestMirrors' temp.json | jq -c)
     # Update ICSP File
     oc patch ImageContentSourcePolicy/$FUSION_ICSP --type='json' -p='[{"op": "replace", "path": "/spec/repositoryDigestMirrors", "value": '$PATCH' }]'
     # Remove temp file
     rm temp.json
   # If we could not find a duplicate source entry in the existing fusion
   # policy file, there is no need to update the current file....just 
   # create a new one
   else
     applyNewPolicyFile   
   fi
# No existing fusion policy file specified, create new policy file
else
  applyNewPolicyFile	
fi
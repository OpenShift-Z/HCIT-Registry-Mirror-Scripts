#!/bin/bash
#
# Copyright IBM Corporation 2023
# Mirror the pacakages needed for the IBM Spectrum Fusion Operator
if [[ $# != 1 ]]; then
  echo "usage: restore.sh <env_file>"
  exit 4
fi
echo env file used is $1
# Make ENV variables available to script at run time
source $1
# Make Sure Fusion Version is set correctly
if [ "${#RESTORE_VERSION}" -le 3 ]; then
  printf "ERROR: Restore Version $RESTORE_VERSION is not supported, check the list of supported versions in your ENV file and try again.\nNote: All releases of Backup and Restore software must include the minor version suffix (e.g, 2.6 must be 2.6.0)\n"
  exit 1
fi
# Issue Skopeo Copy Commands
echo "Issuing Mirror Commands for Fusion"
sh ./versionsRestore/$RESTORE_VERSION
echo "Back and Restore Mirror Completed"
# Copy template Fusion ICSP file
cp templates/icsps/restore.yaml $POLICY_FILE
# Replace Registry in ICSP file
sed -i "s+\$TARGET_PATH+$TARGET_PATH+g" $POLICY_FILE
# Completion Message
echo "Backup and Restore Mirror Script has completed"

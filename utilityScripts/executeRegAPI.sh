#!/bin/bash
#
# Copyright IBM Corporation 2022
# Bash script to capture results from index image API Calls
if [[ $# != 1 ]]
  then
  echo "usage: executeRegAPI.sh <env_var_file>"
  exit 4
fi
echo env file used is $1
# Export our ENV vars
source $1
# Remove result file if it already exists
if test -f "result.out"; then
  rm result.out
fi
# Start the index container image
echo "Start index image container"
podman run --name index_container -p$INDEX_IMAGE_PORT:$INDEX_IMAGE_PORT -d $INDEX_IMAGE
# Run grpcurl for given API CALL
echo "Execute $API_CALL"
grpcurl -plaintext localhost:$INDEX_IMAGE_PORT api.Registry/$API_CALL > temp1.txt
# Stop Container
echo "Stop index image container"
podman stop index_container
# Remove Container
echo "Remove index image container"
podman rm index_container
# Check API Call
if [ "$API_CALL" = "ListPackages" ]; then
  # Remove quotes
  echo "Cleanup packages list"
  cat temp1.txt | awk '{ print $2 }' | tr -d '"' > temp2.txt
  # Remove blank lines
  sed -i '/^$/d' temp2.txt
  # Remove packages file if it already exists
  if test -f "packages.out"; then
    rm packages.out
  fi
  # Create new packages file
  mv temp2.txt packages.out
  # Remove Temp file and display message
  rm temp1.txt
  echo "List of index packages can be found in packages.out"
else
  # Create new results file
  mv temp1.txt result.out
  echo "Result from $API_CALL can be found in result.out"
fi
#!/bin/bash
#
# Copyright IBM Corporation 2023
# Mirror the pacakages needed for the IBM CSI driver block driver to a private registry
if [[ $# != 1 ]]; then
    echo "usage: mirrorBlockDriver.sh <env_file>"
    exit 4
fi

echo env file used is $1
# Make ENV variables available to script at run time
source $1
# Curl down YAML for CSI Driver
curl $OPERATOR_URL > csi-operator.yaml
curl $DRIVER_URL > csi-driver.yaml
# Save operator image with tag
operImage=$(cat csi-operator.yaml | grep -w "image:" | awk '{print $2}')
# Create an array of driver images
readarray -t driverImages < <(cat csi-driver.yaml | grep -w 'repository:' | awk '{print $2}')
# Create an array of driver image tags
readarray -t driverTags < <(cat csi-driver.yaml | grep -w 'tag:' | awk '{print $2}' | tr -d '"')
# Check if the number of driver images matches the number of tags
if [ "${#driverImages[@]}" -eq "${#driverTags[@]}" ]; then
    echo "Create CSI Driver images"
    index=0
# Loop over the image and tag arrays and create a new array joning the images with their corresponding tags
    for image in "${driverImages[@]}"
    do
        completeDriverImages[index++]="$image:${driverTags[$index]}" 
    done
# Added the operator image to our array
completeDriverImages+=($operImage)
fi
# Pull down the driver images, tag them, and push them up for a given registry
for image in "${completeDriverImages[@]}"
do
    echo "Pulling image $image"
    podman pull $image
    # Use RegEx to parse the full image path and extract the name
    imageName=$(echo $image | grep -oP "(?:.(?!\/))+$")
    # Concatenate the registry with the image name to create our new tag
    registryImage=$REGISTRY$imageName
    # Tag image and push it up to our registry
    podman tag $image $registryImage
    echo "Pushing tagged image $registryImage"
    podman push $registryImage
    # Update the operator and driver YAML files to have
    # the new image references pointing to the given registry
    if [[ "$image" == "$operImage" ]]; then
        sed -i "s+$image+$registryImage+g" csi-operator.yaml
    else
        # The CSI driver YAML image references can't have the image tag associated with it
        # Use RegEx to strip off the image tags
        noTagImageName=$(echo $image | grep -oP ".+(?=:)")
        noTagRegistryImage=$(echo $registryImage | grep -oP ".+(?=:)")
        sed -i "s+$noTagImageName+$noTagRegistryImage+g" csi-driver.yaml
    fi
done

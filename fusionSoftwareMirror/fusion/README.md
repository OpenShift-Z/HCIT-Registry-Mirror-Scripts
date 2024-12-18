# Fusion Software Mirroring Scripts

The `fusion.sh` script will handle mirroring the required software to deploy IBM Storage Fusion. The script will also generate the necessary CatalogSource and ImageContentSourcePolicy (ICSP) files required to install Storage Fusion via OperatorHub in OpenShift.

 For further IBM Storage Fusion mirror details please review the official [IBM Storage Fusion Mirror Documentation](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-storage-fusion-images).

- **Note:** All Fusion images used in this mirror automation have been pulled from the IBM Storage Fusion Mirror website.
- **Note:** As of Fusion 2.9, the official method for mirroring Fusion images has switched from the manual skopeo process that is automated here, to a process that relies on the oc-mirror and `oc ibm-pak` plugins. For updated 2.9 mirror documentation see [here](https://www.ibm.com/docs/en/storage-fusion-software/2.9.x?topic=images-mirroring-fusion).

## **Prerequisites**

- Enterprise registry
  - Docker V2   
- OpenShift cluster
  - Enterprise registry pull-secret configured and certificates trusted
- Linux machine running with the following:
  - Podman
  - Registry pull secrets properly configured for `cp.icr.io`, `us.icr.io`, and `registry.redhat.io` registry
  - [OpenShift command-line interface](https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html)
  - [Skopeo](https://github.com/containers/skopeo/blob/main/install.md)
  - Network connectivity to enterprise registry and OpenShift cluster

## **Execution**

1. Clone the GitHub repository to your Linux machine:

```linux
$ git@github.ibm.com:LinuxCoC/hcit-registry-mirror-automation.git
```

2. From `hcit-registry-mirror-automation` directory, access the `fusionSoftwareMirror` folder containing the files needed to run the Fusion mirror bash script:

```linux
hcit-registry-mirror-automation/fusionSoftwareMirror/fusion
$ ls
README.md  fusion.env  fusion.sh  templates  versionsFusion
```

3. Fill out the parameters in the `fusion.env` file:

```linux
# Parameters To Set
export LOCAL_SECRET_JSON=/registry/pull/secret/path # Path to previously configured registry pull-secrets file
export LOCAL_ISF_REGISTRY="mirror_registry" # (e.g: sandboxregistry.fpet.pokprv.stglabs.ibm.com:5000/sandbox )
export LOCAL_ISF_REPOSITORY="mirror_repo_name" # (e.g: fusion-mirror)
export POLICY_FILE=/path/to/icsp/file # File does not have to exist, will be replaced by ICSP template
export CATALOG_SOURCE=/path/to/catalog/file # File does not have to exist, will be replaced by catalog template
export REGUSER="mirror_reg_user" # Username for enterprise registry
export REGPASS="mirror_reg_pass" # Password for enterprise registry
export FUSION_VERSION="fusion_version_num" # Desired Fusion Version from the list below
# Supported Versions:
# - 2.6.1
# - 2.6.0
# - 2.5.2
# - 2.5.1
# - 2.4
# - 2.3
# - 2.2
# Verification
IFS='/' read -r NAMESPACE PREFIX <<< "$LOCAL_ISF_REPOSITORY"
if [[ "$PREFIX" != "" ]]; then export TARGET_PATH="$LOCAL_ISF_REGISTRY/$NAMESPACE/$PREFIX";  export REPO_PREFIX=$(echo "$PREFIX"| sed -r 's/\//-/g')-; else export TARGET_PATH="$LOCAL_ISF_REGISTRY/$NAMESPACE"; export REPO_PREFIX="Not Used"; fi
# Print correctly set variables
echo "Target Registry Path: $TARGET_PATH"
echo "Registry Repo Prefix: $REPO_PREFIX"
```

4. Execute the bash script passing the `fusion.env` file as an argument:

```linux
$ ./fusion.sh fusion.env
```

5. Following completion of the script, review and apply the generated CatalogSource and imageContentSourcePolicy files to your OpenShift cluster:

```linux
$ oc apply -f imageContentSourcePolicy.yaml
$ oc apply -f catalogSource.yaml
```

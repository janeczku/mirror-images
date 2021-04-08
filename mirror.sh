#!/bin/bash

# This script imports a list of images from an upstream container registry to a private registry.
# Please ensure the Docker daemon has been logged in to the private registry if authentication is required
# before running this script.
#
# To import (mirror) images for a specific Rancher release to a private registry follow these steps:
# 1. Download the rancher-image.txt file from the release artefacts of the chosen Rancher version, e.g. https://github.com/rancher/rancher/releases/download/v2.5.6/rancher-images.txt
# 2. Rename the file to "rancher-<VERSION>.imagelist", e.g. "rancher-2.5.6.imagelist"
# 4. Ensure the Docker Daemon is logged in the registry (ie. "docker login ...")
# 3. Run this script with ./mirror -r <registry-hostname>/<optional namespace>

# Trap Ctrl+C
trap trapint 2
function trapint {
    exit 0
}

image_list_ext="imagelist"

usage () {
    echo "USAGE: $0 [--image-list-ext rancher-images]"
    echo "  [-l|--image-list-ext extension] the filename extension of the text file(s) containing the list of images to import. Default: 'imagelist'"
    echo "  [-r|--registry registry:port[/path]] the target private registry"
	echo "  [-h|--help] Usage message"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--registry)
        reg="$2"
        shift # past argument
        shift # past value
        ;;
        -l|--image-list-ext)
        image_list_ext="$2"
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        help="true"
        shift
        ;;
        *)
        usage
        exit 1
        ;;
    esac
done

if [[ $help ]]; then
    usage
    exit 0
fi

if [ -z "$reg" ]
then
	echo "missing registry parameter"
	exit 1
fi

for list in *.${image_list_ext}; do

	echo "### Processing file ${list}"

	while IFS= read -r simage; do
		[ -z "${simage}" ] && continue
		
		# Rewrite target image name
		case $simage in
		*/*)
			timage="${reg}/${simage}"
			#img=${simage#*/}
			#timage="${reg}/${img}"
			;;
		*)
			timage="${reg}/rancher/${simage}"
			# timage="${reg}/${simage}"
			
			;;
		esac
		
		# Check if image already exists in target registry
		if docker manifest inspect $timage >/dev/null 2>&1; then
			echo "+++ Image already imported: ${timage}"
			continue
		fi
		
		echo "+++ Importing image ${timage}"

		# Check if image exists locally
		if docker inspect "${simage}" > /dev/null 2>&1; then
			echo "+++ Image pull success: ${simage}"
		# Pull image from upstream registry
		elif docker pull -q "${simage}" ; then
			echo "+++ Image pull success: ${simage}"
		else
			echo "+++ Image pull failed: ${simage}"
			continue
		fi
		
		# Tag 'n Push
		docker tag "${simage}" "${timage}"
		if docker push -q "${timage}" ; then
			echo "+++ Image push success: ${simage}"
		else
			echo "+++ Image push failed: ${simage}"
		fi
		
	done < "${list}"

done

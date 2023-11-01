#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 docker_image_version"
    exit 1
fi

IMAGE_VERSION=$1
DOCKER_REPO="us.gcr.io/broad-dsde-methods/gatk-workshop-terra-jupyter-images/gatk-workshop-terra-jupyter-image"
DOCKER_IMAGE_TAG="${DOCKER_REPO}:${IMAGE_VERSION}"

gcloud builds submit --tag ${DOCKER_IMAGE_TAG} --timeout=24h --machine-type n1_highcpu_8

if [ $? -ne 0 ]; then
    echo "gcloud builds submit failed"
    exit 1
fi

exit 0

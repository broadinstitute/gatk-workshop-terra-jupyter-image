#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 docker_image_version"
    exit 1
fi

IMAGE_VERSION=$1
IMAGE_NAME="us.gcr.io/broad-dsde-methods/gatk-workshop-terra-jupyter-image"
DOCKER_IMAGE_TAG="${IMAGE_NAME}:${IMAGE_VERSION}"

gcloud builds submit --tag ${DOCKER_IMAGE_TAG} --timeout=24h --machine-type n1_highcpu_32

if [ $? -ne 0 ]; then
    echo "gcloud builds submit failed"
    exit 1
fi

exit 0

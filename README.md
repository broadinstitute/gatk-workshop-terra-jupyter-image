# gatk-workshop-terra-jupyter-image
Terra Jupyter docker image with support for GATK (including Python tools), for GATK/Terra workshop use.

This repository contains a Dockerfile for an image that allows running of GATK tools (including Python-based tools) in the Terra Jupyter notebook environment, suitable for use at GATK/Terra workshops. It pre-installs GATK and the GATK Python environment in a way that doesn't interfere with the base terra-jupyter environment, and allows a GATK-compatible Python kernel to be selected in Jupyter to run GATK tools.

To build the image remotely using Google Cloud Build, run `build_docker_remote.sh <VERSION>`, where `<VERSION>` is the version number you want for the new image. The image will be pushed to the GCR repo `us.gcr.io/broad-dsde-methods/gatk-workshop-terra-jupyter-image:VERSION`

For full instructions on using the image in the Terra Jupyter environment, read [this article](https://github.com/broadinstitute/gatk-workshop-terra-jupyter-image/wiki/Using-the-gatk%E2%80%90workshop%E2%80%90terra%E2%80%90jupyter%E2%80%90image-in-the-Terra-Jupyter-environment).

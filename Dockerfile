# NOTE: By default this image will launch jupyter on startup. To bypass this and obtain a shell with 
# full permissions, run: 
# 
# docker run -it --entrypoint /bin/bash --user root <image_tag>

FROM us.gcr.io/broad-dsp-gcr-public/terra-jupyter-base:1.1.3

ARG GATK_VERSION=4.4.0.0

USER root

# Install Java 17 (required by GATK 4.4), as well as samtools
RUN apt-get update && apt-get install -yq --no-install-recommends \
    openjdk-17-jdk \
    samtools

ENV PIP_USER=false

# Download GATK and install to /gatk, then create the GATK conda environment and 
# install it as a Jupyter kernel
RUN mkdir /gatk && \
    cd /gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip && \
    unzip gatk-$GATK_VERSION.zip && \
    chmod -R 755 /gatk 

RUN conda env create -f /gatk/gatk-$GATK_VERSION/gatkcondaenv.yml 
RUN . activate gatk
RUN conda install -c anaconda ipykernel -y 
RUN pip install --upgrade jupyter_client
RUN python -m ipykernel install --name gatk --display-name "GATK Python Env"
RUN . deactivate

ENV PIP_USER=true
USER jupyter
WORKDIR /home/jupyter

ENV PATH $PATH:/gatk/gatk-$GATK_VERSION

# NOTE: We inherit ENTRYPOINT ["/opt/conda/bin/jupyter", "notebook"] from the base image,
# so no need to repeat it here

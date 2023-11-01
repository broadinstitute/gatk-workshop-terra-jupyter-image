# NOTE: By default this image will launch jupyter on startup. To bypass this and obtain a shell with 
# full permissions, run: 
# 
# docker run -it --entrypoint /bin/bash -e GRANT_SUDO=yes --user root us.gcr.io/broad-dsp-gcr-public/terra-jupyter-base:1.1.3

FROM us.gcr.io/broad-dsp-gcr-public/terra-jupyter-base:1.1.3

ARG GATK_VERSION=4.4.0.0

USER root

RUN apt-get update && apt-get install -yq --no-install-recommends \
    openjdk-17-jdk \
    samtools

USER jupyter
WORKDIR /home/jupyter

RUN wget https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip && \
    unzip gatk-$GATK_VERSION.zip && \
    conda env create -f /home/jupyter/gatk-$GATK_VERSION/gatkcondaenv.yml && \
    source activate gatk && \
    conda install -c anaconda ipykernel -y && \
    pip install --upgrade jupyter_client && \
    python -m ipykernel install --user --name=gatk && \
    source deactivate gatk

ENV PATH $PATH:/home/jupyter/gatk-$GATK_VERSION

# NOTE: We inherit ENTRYPOINT ["/opt/conda/bin/jupyter", "notebook"] from the base image,
# so no need to repeat it here

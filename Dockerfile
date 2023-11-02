# NOTE: By default this image will launch jupyter on startup. To bypass this and obtain a shell with 
# full permissions, run: 
# 
# docker run -it --entrypoint /bin/bash --user root <image_tag>

FROM us.gcr.io/broad-dsp-gcr-public/terra-jupyter-base:1.1.3

ARG GATK_VERSION=4.4.0.0

USER root
ENV HOME /root

# We need bash instead of dash to support the "source" command inside of Jupyter ("." does not work there)
RUN ln -sf /bin/bash /bin/sh

# Install Java 17 (required by GATK 4.4), as well as samtools
RUN apt-get update && apt-get install -yq --no-install-recommends \
    openjdk-17-jdk \
    samtools

# Make sure the GATK Python libs don't get installed into the user's home dir 
ENV PIP_USER=false

# Download GATK and install to /gatk
RUN mkdir /gatk && \
    cd /gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip && \
    unzip gatk-$GATK_VERSION.zip && \
    chmod -R 755 /gatk 

# Install nb_conda_kernels so that it will pick up the GATK conda environment as a kernel automagically
RUN conda install -c conda-forge nb_conda_kernels -y

# Create (but do not activate) the GATK conda environment:
RUN conda env create -f /gatk/gatk-$GATK_VERSION/gatkcondaenv.yml 

# Install ipykernel so that nb_conda_kernels will pick up the GATK conda environment as a kernel.
RUN source activate gatk
RUN conda install -c conda-forge nb_conda_kernels -y
RUN conda install -c anaconda ipykernel -y
RUN pip install --upgrade jupyter_client
RUN python -m ipykernel install --name gatk --display-name gatk
RUN source deactivate

# Nothing to see here...
RUN chmod -R 777 /opt/conda

# Restore PIP_USER to its original value, and switch back to the jupyter user
ENV PIP_USER=true
USER jupyter
WORKDIR /home/jupyter
ENV HOME /home/jupyter

# Make sure gatk gets added to the PATH
ENV PATH $PATH:/gatk/gatk-$GATK_VERSION

# NOTE: We inherit ENTRYPOINT ["/opt/conda/bin/jupyter", "notebook"] from the base image,
# so no need to repeat it here

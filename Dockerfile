# NOTE: By default this image will launch jupyter on startup. To bypass this and obtain a shell with 
# full permissions, run: 
# 
# docker run -it --entrypoint /bin/bash --user root <image_tag>

FROM us.gcr.io/broad-dsp-gcr-public/terra-jupyter-base:1.1.3

ARG GATK_VERSION=4.4.0.0

ENV USER jupyter
ENV USER_EXE_DIR /usr/local/bin 
ENV GATK_CONDA_PATH /gatkconda

ENV HOME /root
USER root

# We need bash instead of dash to support the "source" command inside of Jupyter ("." does not work there)
RUN ln -sf /bin/bash /bin/sh

# We want to grant the jupyter user limited sudo permissions
# without password so they can install the necessary packages that they 
# want to use on the docker container
#
# Need to allow chmod -R g+ws /opt/conda/pkgs/cache as a special case for now, in order to enable non-root/sudo use of conda
RUN mkdir -p /etc/sudoers.d \
    && echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/apt-get install *, /opt/conda/bin/conda install *, /usr/bin/chmod -R g+ws /opt/conda/pkgs/cache, /opt/poetry/bin/poetry install" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

# Install Java 17 (required by GATK 4.4), as well as samtools
RUN apt-get update && apt-get install -yq --no-install-recommends \
    openjdk-17-jdk \
    samtools

# Make sure the GATK Python libs don't get installed into the user's home dir 
ENV PIP_USER=false

# Because /home/jupyter gets completely clobbered at runtime by the Terra persistent disk mount, 
# we need a script to restore some of its contents at runtime. For the same reason, we need to install
# ipykernel in the conda environment live rather than during docker build.
#
# The installation of ipykernel in the conda environment at runtime triggers the creation
# of a "conda env:gatkconda" kernel within jupyter by the nb_conda_kernels library.
#
# The upgrade of the jupyter_client package is necessary to allow this kernel to work.
RUN printf "#!/bin/bash\n \
    mkdir -p /home/jupyter/.conda\n \
    echo $GATK_CONDA_PATH > /home/jupyter/.conda/environments.txt\n \
    source activate $GATK_CONDA_PATH\n \
    sudo /usr/bin/chmod -R g+ws /opt/conda/pkgs/cache\n \
    conda install -c anaconda ipykernel -y\n \
    pip install --upgrade jupyter_client\n \
    exit 0\n" > $USER_EXE_DIR/setup_gatk_env && \
    chmod 755 $USER_EXE_DIR/setup_gatk_env

# Download GATK and install to /gatk
RUN mkdir /gatk && \
    cd /gatk && \
    wget https://github.com/broadinstitute/gatk/releases/download/$GATK_VERSION/gatk-$GATK_VERSION.zip && \
    unzip gatk-$GATK_VERSION.zip && \
    rm /gatk/gatk-$GATK_VERSION.zip && \
    chmod -R 755 /gatk && \
    chown -R $USER:users /gatk && \
    ln -s /gatk/gatk-$GATK_VERSION/gatk $USER_EXE_DIR/gatk && \
    chmod 755 $USER_EXE_DIR/gatk

# Create a user-owned directory for the GATK conda environment
RUN mkdir $GATK_CONDA_PATH && \
    chmod 755 $GATK_CONDA_PATH && \
    chown $USER:users $GATK_CONDA_PATH

# Install nb_conda_kernels into the base environment so that it will pick up the GATK conda environment 
# as a kernel automagically
RUN conda install -c conda-forge nb_conda_kernels -y

# Set the setgid bit on /opt/conda/pkgs/cache so that files within this directory get assigned to the users group
# This is necessary to allow non-root/sudo use of conda.
# TODO: need to also set the default umask so that group write permission is set for new files, otherwise
# TODO: the chmod command needs to be repeated on every conda command
RUN mkdir -p /opt/conda/pkgs/cache && \
    chgrp -R users /opt/conda/pkgs/cache && \
    chmod -R g+ws /opt/conda/pkgs/cache

# Switch back to the jupyter user:
USER jupyter
WORKDIR /home/jupyter
ENV HOME /home/jupyter

# Create (but do not activate) the GATK conda environment in our user-owned directory:
RUN conda env create -f /gatk/gatk-$GATK_VERSION/gatkcondaenv.yml -p $GATK_CONDA_PATH

# Restore PIP_USER to its original value, and switch back to the jupyter user
ENV PIP_USER=true

# We would like to set the PATH for the jupyter user, but it also gets overwritten at runtime in Terra.
# So we symlink what we need into /usr/local/bin instead.
# ENV PATH $PATH:/gatk/gatk-$GATK_VERSION:/gatk

# NOTE: We inherit ENTRYPOINT ["/opt/conda/bin/jupyter", "notebook"] from the base image,
# so no need to repeat it here

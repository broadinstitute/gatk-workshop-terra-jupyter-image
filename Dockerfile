# NOTE: By default this image will launch jupyter on startup. To bypass this and obtain a shell with 
# full permissions, run: 
# 
# docker run -it --entrypoint /bin/bash --user root <image_tag>

FROM us.gcr.io/broad-dsp-gcr-public/terra-jupyter-base:1.1.3

ARG GATK_VERSION=4.4.0.0

ENV USER jupyter

ENV HOME /root
USER root

# We need bash instead of dash to support the "source" command inside of Jupyter ("." does not work there)
RUN ln -sf /bin/bash /bin/sh

# We want to grant the jupyter user limited sudo permissions
# without password so they can install the necessary packages that they 
# want to use on the docker container
RUN mkdir -p /etc/sudoers.d \
        && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
        && chmod 0440 /etc/sudoers.d/$USER

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
    printf "#!/bin/bash\n \
    export PATH=$PATH:/gatk/gatk-$GATK_VERSION:/gatk\n \
    mkdir /home/jupyter/.jupyter 2> /dev/null\n \
    echo \'%s\' > /home/jupyter/.jupyter/jupyter_config.json\n \
    sudo chmod -R 777 /opt/conda/pkgs/cache\n \
    source activate gatk\n \
    conda install -c anaconda ipykernel -y\n \
    exit 0\n" '{ "CondaKernelSpecManager": { "kernelspec_path": "--user" } }' > /gatk/setup_gatk_env && \
    rm /gatk/gatk-$GATK_VERSION.zip && \
    chmod -R 755 /gatk && \
    chown -R $USER:users /gatk

# Install nb_conda_kernels so that it will pick up the GATK conda environment as a kernel automagically
RUN conda install -c conda-forge nb_conda_kernels -y

# RUN mkdir /home/jupyter/.jupyter && \
#     echo '{ "CondaKernelSpecManager": { "kernelspec_path": "/opt/conda" } }' > /home/jupyter/.jupyter/jupyter_config.json && \
#     chmod -R 755 /home/jupyter/.jupyter && \
#     chown -R $USER:users /home/jupyter/.jupyter

# Create (but do not activate) the GATK conda environment:
RUN conda env create -f /gatk/gatk-$GATK_VERSION/gatkcondaenv.yml 

# Install ipykernel so that nb_conda_kernels will pick up the GATK conda environment as a kernel.
# RUN source activate gatk
# RUN conda install -c anaconda ipykernel -y
# RUN pip install --upgrade jupyter_client
# RUN python -m ipykernel install --name gatk --display-name gatk
# RUN source deactivate

# RUN python -m nb_conda_kernels list --CondaKernelSpecManager.kernelspec_path=/opt/conda

# Restore PIP_USER to its original value, and switch back to the jupyter user
ENV PIP_USER=true
USER jupyter
WORKDIR /home/jupyter
ENV HOME /home/jupyter

# Make sure gatk gets added to the PATH
ENV PATH $PATH:/gatk/gatk-$GATK_VERSION:/gatk

# Experiment to see if this helps
# RUN source activate gatk
# RUN sudo /opt/conda/bin/conda install -c anaconda ipykernel -y
# RUN source deactivate

# NOTE: We inherit ENTRYPOINT ["/opt/conda/bin/jupyter", "notebook"] from the base image,
# so no need to repeat it here

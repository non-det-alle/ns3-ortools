
### From base-notebook/Dockerfile in jupyter's docker-stacks ###
# https://github.com/jupyter/docker-stacks.git

# Ubuntu 22.04 (jammy)
# https://hub.docker.com/_/ubuntu/tags?page=1&name=jammy
ARG ROOT_CONTAINER=ubuntu:22.04

FROM $ROOT_CONTAINER

LABEL maintainer="Alessandro Aimi <alleaimi95@gmail.com>"
LABEL Description="Docker image for experiments with the NS-3 Network Simulator"
ARG NB_USER="ns3"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.10

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN PYTHON_SPECIFIER="python${PYTHON_VERSION}" && \
    apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    locales \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in aarch64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    wget \
    # Install Python, Pip, and other necessary packages
    ${PYTHON_SPECIFIER} \
    python3-pip \
    python3-venv \
    ### From minimal-notebook/Dockerfile in jupyter's docker-stacks ###
    # https://github.com/jupyter/docker-stacks.git
    # Common useful utilities
    git \
    nano-tiny \
    tzdata \
    unzip \
    vim-tiny \
    # git-over-ssh
    openssh-client \
    # less is needed to run help in R
    # see: https://github.com/jupyter/docker-stacks/issues/1588
    less \
    # nbconvert dependencies
    # https://nbconvert.readthedocs.io/en/latest/install.html#installing-tex
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    # Enable clipboard on Linux host systems
    xclip \
    ### Install OS dependences needed by Ns-3, Sem, OR-Tools ###
    libboost-math-dev \
    curl \
    pkg-config \
    build-essential \ 
    cmake \ 
    autoconf \
    libtool \
    zlib1g-dev \
    lsb-release \
    libcurlpp-dev \
    htop && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV HOME="/home/${NB_USER}" \
    # Python directory
    PATH="/home/${NB_USER}/.local/bin:${PATH}" \
    # Ns-3 directory
    NS3DIR="/home/${NB_USER}/ns-3-dev" \
    # OR-Tools directory
    LD_LIBRARY_PATH="/usr/local/lib"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Create NB_USER with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${HOME}"

# Create alternative for nano -> nano-tiny
RUN update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10

WORKDIR /tmp

# Install OR-Tools (root needed for install)
RUN git clone https://github.com/non-det-alle/or-tools && \
    cd or-tools && \
    make -j4 third_party && \
    make -j4 cc && \
    make -j4 install_cc && \
    cd .. && \
    rm -rf or-tools

################################################################### USER CHANGE

USER ${NB_UID}

WORKDIR "${HOME}"

# Setup work directory for backward-compatibility
# Install Jupyter Notebook and Lab
# Generate a notebook server config
# Cleanup temporary files and clean Pip cache
# Correct permissions
RUN mkdir "${HOME}/work" && \
    pip install \
    seaborn \
    notebook \
    jupyterlab && \
    pip cache purge && \
    jupyter notebook --generate-config && \
    jupyter lab clean && \
    fix-permissions "${HOME}"

# Install ns-3 with OR-Tools support
RUN git clone https://gitlab.com/non-det-alle/ns-3-dev.git && \
    cd ns-3-dev && \
    ./ns3 configure --enable-examples --disable-gtk --disable-werror \
    -d optimized --out=build/optimized && \
    ./ns3 build && \
    cd .. && \
    fix-permissions "${NS3DIR}"

# Install modified sem that works with recent ./ns3 script
RUN git clone https://github.com/non-det-alle/sem.git && \
    cd sem && \
    pip install poetry2setup && \
    poetry2setup > setup.py && \
    pip uninstall -y\
    poetry2setup \
    poetry_core && \
    pip install -e . && \
    cd .. && \ 
    fix-permissions "${HOME}/sem"

EXPOSE 8888

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh start-singleuser.sh ns3 /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY jupyter_server_config.py ${HOME}/.jupyter/
# Import useful bash configuration
COPY .bashrc ${HOME}/

################################################################### USER CHANGE

# Fix permissions as root
USER root

# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
    ${HOME}/.jupyter/jupyter_server_config.py > ${HOME}/.jupyter/jupyter_notebook_config.py && \
    fix-permissions "${HOME}/.jupyter" && \
    fix-permissions "${HOME}/.bashrc"

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK  --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -O- --no-verbose --tries=1 --no-check-certificate \
    http${GEN_CERT:+s}://localhost:8888${JUPYTERHUB_SERVICE_PREFIX:-/}api || exit 1

################################################################### USER CHANGE

# Switch back to user to avoid accidental container runs as root
USER ${NB_UID}

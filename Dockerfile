
ARG ROOT_CONTAINER=ubuntu:latest

FROM $ROOT_CONTAINER

LABEL maintainer="Alessandro Aimi <alleaimi95@gmail.com>"
LABEL Description="Docker image for experiments with the NS-3 Network Simulator"
ARG NB_USER="alle"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    locales \
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
    pip \
    python3-venv \
    libboost-math-dev \
    curl \
    pkg-config \
    build-essential \ 
    cmake \ 
    autoconf \
    libtool \
    zlib1g-dev \
    lsb-release && \
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
ENV HOME="/home/${NB_USER}"
ENV PATH="${HOME}/.local/bin:${PATH}"
ENV NS3DIR="${HOME}/ns-3-dev/"
ENV LD_LIBRARY_PATH="/usr/local/lib/"

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
    echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/added-by-start-script && \
    fix-permissions "${HOME}"

# Create alternative for nano -> nano-tiny
RUN update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10

# Setup script for ns3
COPY ns3 /usr/local/bin/ns3
RUN chmod a+rx /usr/local/bin/ns3

WORKDIR "${HOME}"

# Install OR-Tools
RUN git clone https://github.com/google/or-tools && \
    cd or-tools && make third_party && make cc && make install_cc && cd .. && \
    rm -rf or-tools

USER ${NB_UID}

COPY .bashrc ${HOME}/.bashrc

# Install poetry and sem 
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    git clone https://github.com/non-det-alle/sem.git && \
    cd sem && poetry install && poetry build && \
    tar -xvf dist/*.tar.gz --wildcards --no-anchored '*/setup.py' --strip=1 && \
    pip install . && cd .. && rm -rf sem

RUN pip install seaborn

# Install ns-3
RUN git clone https://gitlab.com/non-det-alle/ns-3-dev.git && \
    fix-permissions 

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["/bin/bash"]

#RUN fix-permissions "${HOME}"

FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app

# VSCODE ARGS
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn \
    VIRTUAL_ENV=/app/venv \
    WORKDIR=/app \
    PATH="${VIRTUAL_ENV}/bin:${PATH}:${WORKDIR}/bin" \
    DEBIAN_VERSION=buster

# VIRTUAL_ENV split into a seperate ENV call is ensure it's placed into memory before making a 
# depencency on it.
ENV DEBIAN_FRONTEND=dialog \
    ANSIBLE=3.0.0

RUN apt-get update \
    && apt-get install -y sudo gnupg \
    && apt-get install -y --no-install-recommends apt-utils ca-certificates curl apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-${DEBIAN_VERSION}-prod ${DEBIAN_VERSION} main" > /etc/apt/sources.list.d/microsoft.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common powershell

# Install the python virt env.
RUN apt-get install -y sshpass build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev wget \
    && wget https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tar.xz \
    && tar Jxf Python-3.9.0.tar.xz \
    && (cd Python-3.9.0; ./configure; make altinstall) \
    && rm -f Python-3.9.0.tar.xz \
    && rm -rf Python-3.9.0 \
    && apt-get purge -y --no-install-recommends build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev wget \
    && apt-get autoremove -y

RUN apt-get update \
    && /usr/local/bin/python3.9 -m pip install --upgrade pip \
    && /usr/local/bin/pip3.9 install virtualenv \
    && /usr/local/bin/python3.9 -m virtualenv --python=/usr/local/bin/python3.9 $VIRTUAL_ENV \
    && /usr/local/bin/pip3.9 install \
    ansible==$ANSIBLE \
    jinja2 \
    cffi \
    cryptography \
    MarkupSafe \
    netaddr \
    pycparser \
    PyYAML \
    six \
    paramiko

# Clean up apt caches
RUN apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Powershell Installer
RUN /usr/bin/pwsh -Command 'Install-Module powershell-yaml -Scope AllUsers -Force -ErrorAction Stop' \
    # vscode permissions
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "${USERNAME} ALL=\(root\) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # personal tools vscode environment
    && mkdir -p $WORKDIR/repo $WORKDIR/results $WORKDIR/root $WORKDIR/bin $WORKDIR/.vscode

RUN date >> $WORKDIR/inventory.txt \
    && /usr/bin/pwsh -Command '$PSVersionTable' > $WORKDIR/inventory.txt \
    && /usr/bin/pwsh -Command 'get-module -listavailable' >> $WORKDIR/inventory.txt \
    && pip3.9 list >> $WORKDIR/inventory.txt

CMD cat $WORKDIR/inventory.txt

FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS dotnet
WORKDIR /app

# VSCODE ARGS
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn \
    VIRTUAL_ENV=/app/venv \
    WORKDIR=/app

# VIRTUAL_ENV split into a seperate ENV call is ensure it's placed into memory before making a 
# depencency on it.
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}" \
    DEBIAN_FRONTEND=dialog \
    PWSH_YAML=0.4.2 \
    ANSIBLE=2.10.0 \
    JINJA=2.11.2 \
    CFFI=1.14.0 \
    CRYPTGRAPH=2.9.2 \
    MARKUP_SAFE=1.1.1 \
    NETADDR=0.7.19 \
    PKG_RESOURCES=0.0.0 \
    PYCPARSER=2.20 \
    PYYAML=5.3.1 \
    SIX=1.14.0 \
    PARAMIKO=2.7.1

# Install the python virt env.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends apt-utils python3-pkg-resources python3-virtualenv virtualenv sudo \
    && apt-get --yes autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m virtualenv --python=/usr/bin/python3 $VIRTUAL_ENV \
    && pip install \
    ansible==$ANSIBLE \
    jinja2==$JINJA \
    cffi==$CFFI \
    cryptography==$CRYPTGRAPH \
    MarkupSafe==$MARKUP_SAFE \
    netaddr==$NETADDR \
    pkg-resources==$PKG_RESOURCES \
    pycparser==$PYCPARSER \
    PyYAML==$PYYAML \
    six==$SIX \
    paramiko==$PARAMIKO

# Powershell Installer
RUN /usr/bin/pwsh -Command 'Install-Module powershell-yaml -MaximumVersion ${PWSH_YAML_VER} -Scope AllUsers -Force -ErrorAction Stop' \
    # vscode permissions
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # personal tools vscode environment
    && mkdir -p $WORKDIR/repo $WORKDIR/results $WORKDIR/root/ $WORKDIR/bin $WORKDIR/.vscode

RUN date >> $WORKDIR/inventory.txt \
    && pwsh -Command 'get-module -listavailable' > $WORKDIR/inventory.txt \
    && pip list >> $WORKDIR/inventory.txt

CMD cat $WORKDIR/inventory.txt

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 8080

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn \
    VIRTUAL_ENV=/app/venv \
    WORKDIR=/app \
    PATH="${VIRTUAL_ENV}/bin:${PATH}:${WORKDIR}/bin" \
    DEBIAN_VERSION=bullseye

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
    && apt-get install -y --no-install-recommends software-properties-common powershell=7.2.4-1.deb

# Set up python chroot - this saves considerable space over a system-wide installation
# by using python's native dependency management and only installing minimal system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pkg-resources \
    python3-virtualenv \
    virtualenv

RUN mkdir NetworkConfigGenerator

# Set up python chroot then install ansible inside it
ENV VIRTUAL_ENV=/app/venv
RUN python3 -m virtualenv --python=/usr/bin/python3 $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY requirements.txt ./requirements.txt
RUN pip install --upgrade pip && pip install -r ./requirements.txt && pip freeze > ./NetworkConfigGenerator/packagebuild.txt
RUN apt-get update \
    && apt-get install -y sshpass \
    && rm -rf ./requirements.txt

# Clean up apt caches
RUN apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

COPY /poshWebServer.ps1 /app/poshWebServer.ps1
RUN chmod 755 /app/poshWebServer.ps1
#CMD ls -al /app

CMD /app/poshWebServer.ps1

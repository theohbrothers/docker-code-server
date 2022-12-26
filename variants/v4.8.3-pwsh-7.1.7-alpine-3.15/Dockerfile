FROM alpine:3.15
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

RUN DEPS='alpine-sdk bash libstdc++ libc6-compat python3' \
    && apk add --no-cache $DEPS \
    && apk add --no-cache npm nodejs \
    && npm config set python python3 \
    && npm install --global code-server@4.8.3 --unsafe-perm \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    && cd /usr/local/lib/node_modules/code-server/lib/vscode && npm install --legacy-peer-deps \
    && code-server --version \
    && apk del $DEPS

RUN apk add --no-cache bash ca-certificates curl git git-lfs jq nano openssh-client tree

RUN apk add --no-cache sudo
RUN adduser -u 1000 --gecos '' -D user
RUN echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user

ENV LANG=en_US.UTF-8
# Install pwsh
# See: https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.3
RUN apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl
RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust
RUN mkdir -p /opt/microsoft/powershell/7 \
    && curl -sSL https://github.com/PowerShell/PowerShell/releases/download/v7.1.7/powershell-7.1.7-linux-alpine-x64.tar.gz | tar -C /opt/microsoft/powershell/7 -zxf - \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
# Disable telemetry for powershell 7.0.0 and above and .NET core: https://github.com/PowerShell/PowerShell/issues/16234#issuecomment-942139350
ENV POWERSHELL_CLI_TELEMETRY_OPTOUT=1
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV POWERSHELL_UPDATECHECK=Off
ENV POWERSHELL_UPDATECHECK_OPTOUT=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_TELEMETRY_OPTOUT=1
ENV COMPlus_EnableDiagnostics=0
RUN pwsh -version

# Install modules
RUN pwsh -c 'Install-Module Pester -Force -Scope AllUsers -MinimumVersion 4.0.0 -MaximumVersion 4.10.1 -ErrorAction Stop'

# Install extensions
RUN su - user -c 'code-server --install-extension panekj.powershell@2021.10.0'
USER 1000
WORKDIR /home/user
CMD [ "code-server", "--bind-addr", "0.0.0.0:8080", "--disable-telemetry", "--disable-update-check" ]
# syntax=docker/dockerfile:1
FROM alpine:3.17
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
RUN set -eu; \
    echo "TARGETPLATFORM=$TARGETPLATFORM"; \
    echo "TARGETOS=$TARGETOS"; \
    echo "TARGETARCH=$TARGETARCH"; \
    echo "TARGETVARIANT=$TARGETVARIANT"; \
    echo "BUILDPLATFORM=$BUILDPLATFORM"; \
    echo "BUILDOS=$BUILDOS"; \
    echo "BUILDARCH=$BUILDARCH"; \
    echo "BUILDVARIANT=$BUILDVARIANT";

RUN --mount=type=secret,id=GITHUB_TOKEN \
    set -eux; \
    DEPS='alpine-sdk bash libstdc++ libc6-compat python3'; \
    apk add --no-cache $DEPS; \
    # Constraint to npm 8, or else npm will fail with 'npm ERR! python is not a valid npm option'. See: https://stackoverflow.com/questions/74522956/python-is-not-a-valid-npm-option and https://jubianchi.github.io/semver-check/#/~8/8
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.15/main npm~8; \
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.17/main nodejs~18; \
    # Install kerberos dependencies https://github.com/coder/code-server/issues/6535
    apk add --no-cache krb5-dev; \
    npm config set python python3; \
    # Use 'NODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT' to fix node 18.20 and 20.12 making experimental API the default, which breaks builds
    ( set +x; export GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ); set -x; CXXFLAGS='-DNODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT' npm install --global code-server@4.17.1 --unsafe-perm ); \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    ( cd /usr/local/lib/node_modules/code-server/lib/vscode; set +x; export GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ); set -x; CXXFLAGS='-DNODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT' npm install --legacy-peer-deps ); \
    code-server --version; \
    apk del $DEPS

# Install tools
RUN set -eux; \
    apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs github-cli iotop jq less lsblk make nano openssh-client openssl p7zip rsync tree yq

# Install pwsh
# See: https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.3
RUN set -eux; \
    apk add --no-cache \
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
RUN set -eux; \
    mkdir -p /opt/microsoft/powershell/7; \
    curl -sSL https://github.com/PowerShell/PowerShell/releases/download/v7.2.8/powershell-7.2.8-linux-alpine-x64.tar.gz | tar -C /opt/microsoft/powershell/7 -zxf -; \
    chmod +x /opt/microsoft/powershell/7/pwsh; \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
# Disable telemetry for powershell 7.0.0 and above and .NET core: https://github.com/PowerShell/PowerShell/issues/16234#issuecomment-942139350
ENV POWERSHELL_CLI_TELEMETRY_OPTOUT=1
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV POWERSHELL_UPDATECHECK=Off
ENV POWERSHELL_UPDATECHECK_OPTOUT=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_TELEMETRY_OPTOUT=1
ENV COMPlus_EnableDiagnostics=0
RUN pwsh -version
# Install pwsh module(s)
RUN pwsh -c 'Install-Module Pester -Force -Scope AllUsers -MinimumVersion 4.0.0 -MaximumVersion 4.10.1 -ErrorAction Stop'

RUN apk add --no-cache sudo
RUN adduser -u 1000 --gecos '' -D user
RUN echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user

# Install common extensions
USER user
# beautify - code formatter
RUN code-server --install-extension hookyqr.beautify@1.4.11
# docker
RUN code-server --install-extension ms-azuretools.vscode-docker@1.18.0
# firefox
RUN code-server --install-extension firefox-devtools.vscode-firefox-debug@2.9.1
# git
RUN code-server --install-extension donjayamanne.githistory@0.6.19
RUN code-server --install-extension eamodio.gitlens@11.6.0
# github. Install the latest compatible version
RUN code-server --install-extension github.vscode-pull-request-github
# gitlab
RUN code-server --install-extension gitlab.gitlab-workflow@3.60.0
# jinja
RUN code-server --install-extension samuelcolvin.jinjahtml@0.16.0
RUN code-server --install-extension wholroyd.jinja@0.0.8
# kubernetes
RUN code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools@1.3.11
# markdown
RUN code-server --install-extension bierner.markdown-preview-github-styles@0.1.6
RUN code-server --install-extension DavidAnson.vscode-markdownlint@0.43.2
# prettier - code formatter
RUN code-server --install-extension esbenp.prettier-vscode@9.0.0
# pwsh
RUN code-server --install-extension ms-vscode.powershell@2021.12.0
# svg
RUN code-server --install-extension jock.svg@1.4.17
# terraform
RUN code-server --install-extension hashicorp.terraform@2.14.0
# toml
RUN code-server --install-extension bungcip.better-toml@0.3.2
# vscode
RUN code-server --install-extension vscode-icons-team.vscode-icons@11.13.0
# xml
RUN code-server --install-extension redhat.vscode-xml@0.18.0
# yaml
RUN code-server --install-extension redhat.vscode-yaml@1.9.1

# Add a default settings.json
USER user
COPY --chown=1000:1000 settings.json /home/user/.local/share/code-server/User/settings.json

# Remove the default code-server config file created when extensions are installed
USER user
RUN rm -fv ~/.config/code-server/config.yaml

# Symlink code to code-server
USER root
RUN ln -sfn /usr/local/bin/code-server /usr/local/bin/code

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV LANG=en_US.UTF-8
USER user
WORKDIR /home/user
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "--bind-addr=0.0.0.0:8080", "--disable-telemetry", "--disable-update-check" ]

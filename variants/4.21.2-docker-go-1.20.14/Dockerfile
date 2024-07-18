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
    # Use '-U_FORTIFY_SOURCE' to fix vsnprintf errors in alpine: https://gitlab.alpinelinux.org/alpine/aports/-/issues/8626
    # Use '-DUSE_IPO=OFF -DWHOLE_PROGRAM_OPTIMISATION=OFF' to fix lto-wrapper errors?
    ( set +x; export GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ); set -x; CXXFLAGS='-DNODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT' npm install --global code-server@4.21.2 --unsafe-perm ); \
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

# Install docker
# See: https://github.com/moby/moby/blob/v20.10.22/project/PACKAGERS.md
# Install docker-cli dependencies
USER root
RUN set -eux; \
    apk add --no-cache \
        ca-certificates \
        git \
        # Workaround for golang 1.15 not producing static binaries. See: https://github.com/containerd/containerd/issues/5824
        libc6-compat \
        openssh-client
# Install dockerd dependencies
RUN apk add --no-cache \
        btrfs-progs \
        e2fsprogs \
        e2fsprogs-extra \
        ip6tables \
        iptables \
        openssl \
        pigz \
        shadow-uidmap \
        xfsprogs \
        xz \
        zfs
# Add userns-remap support. See: https://docs.docker.com/engine/security/userns-remap/
RUN set -eux; \
    addgroup -S dockremap; \
    adduser -S -G dockremap dockremap; \
    echo 'dockremap:231072:65536' >> /etc/subuid; \
    echo 'dockremap:231072:65536' >> /etc/subgid
# Install docker
RUN set -eux; \
    case "$( uname -m )" in \
        'x86_64') \
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-24.0.9.tgz'; \
            ;; \
        'armhf') \
            URL='https://download.docker.com/linux/static/stable/armel/docker-24.0.9.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-24.0.9.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-24.0.9.tgz'; \
            ;; \
        # These architectures are no longer supported as of docker 20.10.x
        # 'ppc64le') \
        # 	URL='https://download.docker.com/linux/static/stable/ppc64le/docker-24.0.9.tgz'; \
        # 	;; \
        # 's390x') \
        # 	URL='https://download.docker.com/linux/static/stable/s390x/docker-24.0.9.tgz'; \
        # 	;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -q "$URL" -O docker.tgz; \
    tar -xvf docker.tgz --strip-components=1 --no-same-owner --no-same-permissions -C /usr/local/bin; \
    ls -al /usr/local/bin; \
    rm -v docker.tgz; \
    containerd --version; \
    ctr --version; \
    docker --version; \
    dockerd --version; \
    runc --version
# Install bash completion
RUN wget -q https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker
# Post-install docker. See: https://docs.docker.com/engine/install/linux-postinstall/
RUN set -eux; \
    addgroup docker; \
    adduser user docker;
VOLUME /var/lib/docker

# Install docker-compose v1 (deprecated, but for backward compatibility)
USER root
RUN apk add --no-cache docker-compose

# Install docker-compose
RUN set -eux; \
    DOCKER_COMPOSE_VERSION=v2.29.0; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-x86_64"; \
            SHA256=fb3f6c317056ec54e8756851663ca788521f7a9c60afb8a595bc7a05ffaa8951; \
            ;; \
        'x86_64') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-x86_64"; \
            SHA256=fb3f6c317056ec54e8756851663ca788521f7a9c60afb8a595bc7a05ffaa8951; \
            ;; \
        'armhf') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-armv6"; \
            SHA256=e1f2942bff7e16556675e46db6e30d6ecbed2e78656c760b8e25383817b7a328; \
            ;; \
        'armv7l') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-armv7"; \
            SHA256=7ca096778a30c349816f67ce772709164eddaf3022901bf55472ae3134264cf6; \
            ;; \
        'aarch64') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-aarch64"; \
            SHA256=49941418051846d72c74dd8df1f8b4ff753ca74d29986361d937384fbfb63569; \
            ;; \
        'ppc64le') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-ppc64le"; \
            SHA256=45606de42e140e20eadb7f8a9db62f783de7df6c148640cd67cf8f9ef3aaab99; \
            ;; \
        'riscv64') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-riscv64"; \
            SHA256=e685bb6ad60225dc099acf85cfbb928e5ceef26a1a61f4995d1fbabac438d0e2; \
            ;; \
        's390x') \
            URL="https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-linux-s390x"; \
            SHA256=94622d0476d9f59b40c24daa22231c603a93fd9acc984c4427ca946dfb4a908c; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=docker-compose; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    mkdir -pv /usr/libexec/docker/cli-plugins; \
    mv -v docker-compose /usr/libexec/docker/cli-plugins/docker-compose; \
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose; \
    docker compose version; \
    :

# Install docker-buildx
RUN set -eux; \
    DOCKER_BUILDX_VERSION=v0.12.1; \
    case "$( uname -m )" in \
        'x86_64') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-amd64"; \
            SHA256=716321df8ca9c82ffe96f37e9f4aa1199d4969795836dbd57ef72d12e3ac5085; \
            ;; \
        'armhf') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-arm-v6"; \
            SHA256=4b3c78b59c0383ab21327e2902af2ea317e3b85e442b1cd776f0c2a7bbbb2999; \
            ;; \
        'armv7l') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-arm-v7"; \
            SHA256=fe0a9e7812051a72c47d009bf9373e76e23644cc3291c848ac4a9b6f237e9e75; \
            ;; \
        'aarch64') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-arm64"; \
            SHA256=fb72d627f2ee080bba70375c367f4292867821e29ca9a8cf485622f6ede8f436; \
            ;; \
        'ppc64le') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-ppc64le"; \
            SHA256=1c649498d727183d82fb243e08856533ea90e8d63bfcd6f8b23b264dbcf7ea7a; \
            ;; \
        'riscv64') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-riscv64"; \
            SHA256=152e7b423c1ce888eb0a658321eb8c28cc1d09af01acd5c66eddf8474dddf55c; \
            ;; \
        's390x') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.1/buildx-v0.12.1.linux-s390x"; \
            SHA256=acee98a9f0550bf2c6c1161cf8067c031ddf0c566c41de7db27847bb72e8ee0b; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=docker-buildx; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    mkdir -pv /usr/libexec/docker/cli-plugins; \
    mv -v docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx; \
    chmod +x /usr/libexec/docker/cli-plugins/docker-buildx; \
    docker buildx version; \
    :

# Install binary tool(s)
RUN set -eux; \
    wget https://github.com/GoogleContainerTools/container-diff/releases/download/v0.17.0/container-diff-linux-amd64 -O container-diff; \
    sha256sum container-diff | grep '^818c219ce9f9670cd5c766b9da5036cf75bbf98bc99eb258f5e8f90e80367c88 '; \
    mv container-diff /usr/local/bin/container-diff; \
    chmod +x /usr/local/bin/container-diff; \
    container-diff version

# Install golang binaries from official golang image
# See: https://go.dev/dl/
USER root
ENV GOLANG_VERSION 1.20.14
ENV PATH=/usr/local/go/bin:$PATH
COPY --from=golang:1.20.14-alpine /usr/local/go /usr/local/go
RUN go version

# Install development tools
RUN set -eux; \
    export GOBIN=/usr/local/bin; \
    go install github.com/go-delve/delve/cmd/dlv@v1.20.1; \
    dlv version; \
    go install golang.org/x/tools/gopls@v0.11.0; \
    gopls version; \
    rm -rf ~/go;

# Install extensions
USER user
RUN code-server --install-extension golang.go@0.38.0

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

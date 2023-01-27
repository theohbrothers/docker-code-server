ARG BASE_IMAGE
FROM $BASE_IMAGE

# Install docker
# See: https://github.com/moby/moby/blob/v20.10.22/project/PACKAGERS.md
# Install docker-cli dependencies
USER root
RUN apk add --no-cache \
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
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-20.10.23.tgz'; \
            ;; \
        'armhf') \
            URL='https://download.docker.com/linux/static/stable/armel/docker-20.10.23.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-20.10.23.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-20.10.23.tgz'; \
            ;; \
        # These architectures are no longer supported as of docker 20.10.x
        # 'ppc64le') \
        # 	URL='https://download.docker.com/linux/static/stable/ppc64le/docker-20.10.23.tgz'; \
        # 	;; \
        # 's390x') \
        # 	URL='https://download.docker.com/linux/static/stable/s390x/docker-20.10.23.tgz'; \
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
RUN wget -q https://raw.githubusercontent.com/docker/cli/v20.10.23/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker
# Post-install docker. See: https://docs.docker.com/engine/install/linux-postinstall/
RUN set -eux; \
    addgroup docker; \
    adduser user docker;
VOLUME /var/lib/docker

# Install docker-compose v1 (deprecated, but for backward compatibility)
USER root
RUN apk add --no-cache docker-compose

# Install docker compose v2. See: https://github.com/docker/compose/releases/
USER root
RUN set -eux; \
    case "$( uname -m )" in \
        'x86_64')  \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-x86_64; \
            SHA256=bcfd9ea51dee4c19dccdfaeef0e7956ef68bf14f3d175933742061a7271ef0f5; \
            ;; \
        'armhf')  \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-armv6; \
            SHA256=a8934600100af88f535eb50b45c7d8d2ac37835221803ba2910e0b167b3af22e; \
            ;; \
        'armv7') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-armv7; \
            SHA256=e5b03ac1258ad4243af0ac4afcb1c6cc8c9956b2483a50309cdb38cdb8387e37; \
            ;; \
        'aarch64') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-aarch64; \
            SHA256=14d31297794868520cb2e61b543bb1c821aaa484af22b397904314ae8227f6a2; \
            ;; \
        'ppc64le') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-ppc64le; \
            SHA256=bdada874a26d382b20ced7c170707a1ebcf9f20d7d6f394b962076968473ca9c; \
            ;; \
        'riscv64') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-riscv64; \
            SHA256=9cc1b9c8de313a1e43b8f3dcca47c29eeb87af3de24c67448c463bf882166430; \
            ;; \
        's390x') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-s390x; \
            SHA256=cf311824af115d0bece5d5d60a73464912dad07cdd00fdaa469dabbcad60f289; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -qO- "$URL" > docker-compose \
    && sha256sum docker-compose | grep "^$SHA256 " \
    && mkdir -pv /usr/libexec/docker/cli-plugins \
    && mv -v docker-compose /usr/libexec/docker/cli-plugins/docker-compose \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose \
    && docker compose version

# Install docker buildx plugin. See: https://github.com/docker/buildx
USER root
RUN set -eux; \
    case "$( uname -m )" in \
        'x86_64')  \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64; \
            SHA256=a7fb95177792ca8ffc7243fad7bf2f33738b8b999a184b6201f002a63c43d136; \
            ;; \
        'armhf')  \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-arm-v6; \
            SHA256=159925b4e679eb66e7f0312c7d57a97e68a418c1fa602a00dd8b29b6406768f0; \
            ;; \
        'armv7') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-arm-v7; \
            SHA256=ba8e5359ce9ba24fec6da07f73591c1b20ac0797a2248b0ef8088f57ae3340fc; \
            ;; \
        'aarch64') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-arm64; \
            SHA256=bbf6a76bf9aef9c5759ff225b97ce23a24fc11e4fa3cdcae36e5dcf1de2cffc5; \
            ;; \
        'ppc64le') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-ppc64le; \
            SHA256=1b2441886e556c720c1bf12f18f240113cc45f9eb404c0f162166ca1c96c1b60; \
            ;; \
        'riscv64') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-riscv64; \
            SHA256=c32372dad653fc70eb756b2cffd026e74425e807c01accaeed4559da881ff57c; \
            ;; \
        's390x') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-s390x; \
            SHA256=90b0ecf315d741888920dddeac9fe2e141123c4fe79465b7b10fe23521c9c366; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -qO- "$URL" > docker-buildx \
    && sha256sum docker-buildx | grep "^$SHA256 " \
    && mkdir -pv /usr/libexec/docker/cli-plugins \
    && mv -v docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-buildx \
    && docker buildx version

USER root

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
USER user
RUN code-server --install-extension ms-vscode.powershell@2021.12.0

# Remove the default code-server config file created when extensions are installed
USER user
RUN rm -fv ~/.config/code-server/config.yaml

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV LANG=en_US.UTF-8
USER user
WORKDIR /home/user
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "--bind-addr=0.0.0.0:8080", "--disable-telemetry", "--disable-update-check" ]

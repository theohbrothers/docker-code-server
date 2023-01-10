ARG BASE_IMAGE
FROM $BASE_IMAGE

USER root

# Install rootless docker
# See: https://docs.docker.com/engine/security/rootless/
RUN apk add --no-cache shadow-uidmap fuse-overlayfs iproute2 iptables ip6tables
RUN echo user:100000:65536 >/etc/subuid
RUN echo user:100000:65536 >/etc/subgid
USER user
RUN wget -qO- https://get.docker.com/rootless | sh
ENV XDG_RUNTIME_DIR=/home/user/.docker/run
ENV PATH=/home/user/bin:$PATH
ENV DOCKER_HOST=unix:///home/user/.docker/run/docker.sock

USER root

# Install docker compose v2
RUN apk add --no-cache docker-cli-compose

# Install docker-compose v1 (deprecated, but for backward compatibility)
RUN apk add --no-cache docker-compose

# Install docker buildx plugin
USER root
RUN set -eux; \
    case "$( apk --print-arch )" in \
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

# Remove the default code-server config file created when extensions are installed
USER user
RUN rm -fv ~/.config/code-server/config.yaml

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV LANG=en_US.UTF-8
USER user
WORKDIR /home/user
CMD [ "/docker-entrypoint.sh" ]
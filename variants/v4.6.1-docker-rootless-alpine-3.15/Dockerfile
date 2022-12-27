ARG BASE_IMAGE
FROM $BASE_IMAGE

USER root

# Install rootless docker
# See: https://docs.docker.com/engine/security/rootless/
RUN apk add --no-cache shadow-uidmap fuse-overlayfs iproute2 iptables ip6tables
RUN apk add --no-cache bash-completion
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
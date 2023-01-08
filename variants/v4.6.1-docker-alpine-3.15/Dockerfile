ARG BASE_IMAGE
FROM $BASE_IMAGE

USER root

# Install docker
# See: https://github.com/moby/moby/blob/v20.10.22/project/PACKAGERS.md
# Install docker client dependencies
RUN apk add --no-cache \
        ca-certificates \
        git \
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
RUN apk add --no-cache docker
RUN adduser user docker
VOLUME /var/lib/docker

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
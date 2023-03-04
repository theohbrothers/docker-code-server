# syntax=docker/dockerfile:1
# The syntax=docker/dockerfile:1 line above is needed for passing secrets to the build

FROM alpine:3.15
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

RUN --mount=type=secret,id=GITHUB_TOKEN \
    DEPS='alpine-sdk bash libstdc++ libc6-compat python3' \
    && apk add --no-cache $DEPS \
    # Constraint to npm 8, or else npm will fail with 'npm ERR! python is not a valid npm option'. See: https://stackoverflow.com/questions/74522956/python-is-not-a-valid-npm-option and https://jubianchi.github.io/semver-check/#/~8/8
    && apk add --no-cache 'npm~8' 'nodejs~16' \
    && npm config set python python3 \
    && GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ) npm install --global code-server@4.8.3 --unsafe-perm \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    && cd /usr/local/lib/node_modules/code-server/lib/vscode && GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ) npm install --legacy-peer-deps \
    && code-server --version \
    && apk del $DEPS

# Install tools
RUN apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs iotop jq less lsblk make nano openssh-client openssl p7zip rsync tree yq

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

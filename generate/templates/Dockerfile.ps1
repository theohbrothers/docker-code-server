@"
FROM $( $VARIANT['_metadata']['distro'] ):$( $VARIANT['_metadata']['distro_version'] )
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on `$BUILDPLATFORM, building for `$TARGETPLATFORM"

RUN DEPS='alpine-sdk libstdc++ libc6-compat python3' \
    && apk add --no-cache `$DEPS \
    && apk add --no-cache npm nodejs \
    && npm config set python python3 \
    && npm install --global code-server@$( $VARIANT['_metadata']['package_version'] ) --unsafe-perm \
    && code-server --version \
    && apk del `$DEPS

RUN apk add --no-cache sudo
RUN adduser -u 1000 -D user
RUN echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user

RUN apk add bash

USER 1000
WORKDIR /home/user
CMD [ "code-server", "--bind-addr", "0.0.0.0:8080" ]
"@

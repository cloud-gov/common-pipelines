# Dockerfile using our hardened base image
ARG base_image

FROM golang:1.21 as builder
ADD . /go/src/github.com/telia-oss/github-pr-resource
WORKDIR /go/src/github.com/telia-oss/github-pr-resource
RUN curl -sL https://taskfile.dev/install.sh | sh
RUN ./bin/task build

FROM ${base_image} AS resource
COPY --from=builder /go/src/github.com/telia-oss/github-pr-resource/build /opt/resource
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef"
RUN apt install -y --no-install-recommends \
    git \
    git-lfs \
    openssh-server \
    openssh-client \
    git-crypt \
    && chmod +x /opt/resource/*
COPY scripts/askpass.sh /usr/local/bin/askpass.sh

FROM resource
LABEL MAINTAINER=telia-oss

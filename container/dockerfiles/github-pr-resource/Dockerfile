ARG base_image

FROM golang:1.14 as builder
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
    && chmod +x /opt/resource/*
COPY scripts/askpass.sh /usr/local/bin/askpass.sh
ADD scripts/install_git_crypt.sh install_git_crypt.sh
RUN ./install_git_crypt.sh && rm ./install_git_crypt.sh

FROM resource
LABEL MAINTAINER=telia-oss

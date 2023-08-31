ARG base_image
FROM golang:1.14 as builder

ENV CONCOURSE_CODE_PATH ${GOPATH}/src/github.com/concourse/semver-resource
COPY --from=builder /opt/resource /opt/resource
FROM ${base_image} AS resource
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef"
RUN apt install -y --no-install-recommends \
    git \
    bash 

ADD . /code

RUN mkdir -p $(dirname ${CONCOURSE_CODE_PATH}) \
    && ln -s /code ${CONCOURSE_CODE_PATH}

RUN cd ${CONCOURSE_CODE_PATH} \
  && go get -v -d ./...

RUN cd ${CONCOURSE_CODE_PATH} \
  && ./scripts/build

RUN cd ${CONCOURSE_CODE_PATH} \
  && mkdir -p /opt/resource \
  && cp assets/* /opt/resource

RUN rm -rf ${GOPATH} ${GOROOT} /usr/local/go /code
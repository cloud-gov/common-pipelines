ARG base_image

FROM golang:1.21 as builder

WORKDIR /usr/src/app

COPY . .

ADD https://curl.haxx.se/ca/cacert.pem /etc/ssl/certs/ca-certificates.crt

RUN export GOPATH=$PWD/go && export PATH=$GOPATH/bin:$PATH

RUN go mod download && \
go build -o /opt/resource/check check/cmd/*.go && \
go build -o /opt/resource/in in/cmd/*.go && \
go build -o /opt/resource/out out/cmd/*.go

FROM ${base_image} AS resource
COPY --from=builder /opt/resource/ /opt/resource/

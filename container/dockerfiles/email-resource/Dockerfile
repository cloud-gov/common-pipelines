ARG base_image

FROM golang:1.21 as builder

WORKDIR /usr/src/app

COPY . .

RUN mkdir ~/.ssh/ && touch ~/.ssh/known_hosts && \
ssh-keyscan github.com >>~/.ssh/known_hosts

ADD https://curl.haxx.se/ca/cacert.pem /etc/ssl/certs/ca-certificates.crt

RUN export GOPATH=$PWD/go && export PATH=$GOPATH/bin:$PATH

RUN go mod download && \
go build -o /opt/resource/check check/cmd/*.go && \
go build -o /opt/resource/in in/cmd/*.go && \
go build -o /opt/resource/out out/cmd/*.go

RUN go test ./... -v

FROM ${base_image} AS resource
COPY --from=builder /opt/resource/ /opt/resource/

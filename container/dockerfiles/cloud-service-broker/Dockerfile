# Dockerfile using our hardened base image
ARG base_image

# Adapted from https://github.com/cloudfoundry/cloud-service-broker/blob/main/Dockerfile
FROM golang:1.22 AS build
WORKDIR /app
ADD . /app

ARG CSB_VERSION=0.0.0
RUN GOOS=linux go build -o ./build/cloud-service-broker -ldflags "-X github.com/cloudfoundry/cloud-service-broker/utils.Version=$CSB_VERSION"

FROM ${base_image}

COPY --from=build /app/build/cloud-service-broker /bin/cloud-service-broker

ADD https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem /usr/local/share/ca-certificates/
RUN update-ca-certificates

ENV PORT 8080
EXPOSE 8080/tcp

WORKDIR /bin
ENTRYPOINT ["/bin/cloud-service-broker"]
CMD ["help"]

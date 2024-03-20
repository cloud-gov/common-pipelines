# Dockerfile using our hardened base image
ARG base_image

# Adapted from https://github.com/cloudfoundry/cloud-service-broker/blob/main/Dockerfile
FROM golang:1.22 AS build
WORKDIR /app
ADD . /app

ARG CSB_VERSION=0.0.0
RUN GOOS=linux go build -o ./build/csb -ldflags "-X github.com/cloudfoundry/cloud-service-broker/utils.Version=$CSB_VERSION"

FROM ${base_image}

COPY --from=build /app/build/csb /app/csb

# Install RDS certificate bundle to support connecting to RDS instances.
# Link from: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html#UsingWithRDS.SSL.GovCloudCertificates
ADD https://truststore.pki.us-gov-west-1.rds.amazonaws.com/global/global-bundle.pem /usr/local/share/ca-certificates/
# Extension must be .crt for ca-certificates to detect it.
RUN mv /usr/local/share/ca-certificates/global-bundle.pem /usr/local/share/ca-certificates/global-bundle.crt
# update-ca-certificates will spuriously output the following:
# "rehash: warning: skipping global-bundle.pem,it does not contain exactly one certificate or CRL"
# You can verify that global-bundle.crt was not skipped by grepping /etc/ssl/certs/ca-certificates.crt
# for the certs from global-bundle.crt in the final image.
RUN update-ca-certificates

ENV PORT 8080
EXPOSE 8080/tcp

WORKDIR /app
ENTRYPOINT ["/app/csb"]
CMD ["help"]

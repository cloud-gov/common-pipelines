ARG base_image

FROM ${base_image} AS tests
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef"
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  curl \
  ca-certificates \
  jq \
  ruby

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*
ADD . /resource
WORKDIR /resource
RUN gem install bundler -v 2.5
RUN bundle install --local && bundle exec rspec

FROM ${base_image} AS resource
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef"
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  ca-certificates \
  jq \
  curl

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*

FROM resource

ARG base_image

FROM ${base_image} AS tests
RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef"
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
  curl \
  ca-certificates \
  jq \
  wget

# Install Ruby from source
ENV RUBY_RELEASE_VERSION=3.4.7
RUN wget -q "https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_RELEASE_VERSION}.tar.gz"
RUN tar xaf "ruby-${RUBY_RELEASE_VERSION}.tar.gz"
RUN cd ruby-${RUBY_RELEASE_VERSION}" && \
  ./configure -q && \
  make -s -j $(nproc) && \
  make -s install
RUN rm -f "ruby-${RUBY_RELEASE_VERSION}.tar.gz" && rm -rf "ruby-${RUBY_RELEASE_VERSION}"

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*
ADD . /resource
WORKDIR /resource
RUN gem install bundler -v 2.6
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

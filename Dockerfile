FROM centos:7.3.1611
MAINTAINER Jussi Heikkilä <jussih@gmail.com>
ENV OTP_VERSION="21.2.6"
ENV OTP_HASH="aa0b95031e7c01af8a7042a00974ab16ed8fec305a68d7dbaa4185e5d58ef4d5"
ENV ELIXIR_VERSION="1.8.1"
ENV ELIXIR_HASH="de8c636ea999392496ccd9a204ccccbc8cb7f417d948fd12692cda2bd02d9822"

# Install Erlang
RUN yum update -y && yum clean all
RUN yum install -y curl && yum clean all
RUN yum install -y gcc gcc-c++ glibc-devel m4 make ncurses-devel openssl openssl-devel autoconf git && yum clean all
RUN curl -fSL -o otp-src.tar.gz "https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz"
RUN echo "$OTP_HASH  otp-src.tar.gz" | sha256sum -c -
ENV ERL_TOP="/usr/local/src/erlang"
RUN mkdir -p $ERL_TOP
RUN tar -zxC $ERL_TOP -f otp-src.tar.gz --strip-components=1
RUN rm otp-src.tar.gz
RUN cd $ERL_TOP && ./otp_build autoconf && ./configure && make -j$(nproc) && make install

# Install Elixir
# localedef is a hack to fix locales getting screwed when running yum.
# this is some bug in the base image probably
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 
ENV LANG="en_US.utf8"

RUN curl -fSL -o elixir-src.tar.gz "https://github.com/elixir-lang/elixir/archive/v${ELIXIR_VERSION}.tar.gz"
RUN echo "$ELIXIR_HASH  elixir-src.tar.gz" | sha256sum -c -
RUN mkdir -p /usr/local/src/elixir
RUN tar -zxC /usr/local/src/elixir/ -f elixir-src.tar.gz --strip-components=1
RUN rm elixir-src.tar.gz
RUN cd /usr/local/src/elixir/ && make && make install

# Install Hex
RUN mix local.hex --force

# Install Rebar
RUN mix local.rebar --force

CMD ["iex"]

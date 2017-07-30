FROM centos:7.3.1611
MAINTAINER Jussi Heikkilä <jussih@gmail.com>
ENV OTP_VERSION="20.0.1"
ENV OTP_HASH="8b121b38102acd43f89afd786055461741522c3a13ee17ef1a795c0dbf6aa281"
ENV ELIXIR_VERSION="1.4.5"
ENV ELIXIR_HASH="bef1a0ea7a36539eed4b104ec26a82e46940959345ed66509ec6cc3d987bada0"

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

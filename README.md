# Ircord

Discord to IRC to Discord bridge. Echoes chat between a Discord channel and an
IRC channel.

## Requirements

Tested with Elixir 1.8 and Erlang OTP 21.

## Installation

- Clone the repository
- Run `mix deps.get`
- Run `mix compile`
- Create a configuration by copying `config/confix.exs` to
  `config/dev.exs` and filling in the blanks.
- Execute with iex `iex -S mix`

## Deploying

- Create a production configuration by copying `config/confix.exs` to
  `config/prod.exs` and filling in the blanks.
- Generate default release configuration `mix release.init`
- Run `MIX_ENV=prod mix release --env=prod` to build a deployable tar archive
  with included Erlang runtime
- The release will be built to `_build/prod/rel/ircord/releases/VERSION`
- Read more from the Distillery documentation: https://hexdocs.pm/distillery/

## Upgrading

- Create an upgrade release `MIX_ENV=prod mix release --upgrade --upfrom=0.1.0 --env=prod`
- Upload the resulting tarball from `_build/prod/rel/ircord/releases/VERSION/ircord.tar.gz` to the server, into `<deployment_root>/releases/VERSION/ircord.tar.gz`
- Run `bin/ircord upgrade 0.2.0`
- That's it (unless the upgrade requires something complicated like mutating genserver states)

### Centos

There is a premade Dockerfile for building a release for Centos 7.3.1611

- Build the Docker image `docker build -t centos-elixir:7.3.1611 .`
- Run a shell in the image, mapping your code directory inside the container 
  `docker run -it --rm -v $PWD:/usr/local/src/ircord centos-elixir:7.3.1611 /bin/bash`
- Inside the container:
  - `cd /usr/local/src/ircord`
  - `mix release.init`
  - `MIX_ENV=prod mix release --env=prod`
- The release will be built to `_build/prod/rel/ircord/releases/VERSION`
- Deploy to your server `rsync -avz _build/prod/rel/ircord/ <username>@<hostname>:<path>/ircord`

### Ubuntu

There is a premade Dockerfile for building a release for Ubuntu 18.04

- Build the Docker image `docker build -t ubuntu-elixir:18.04 -f Dockerfile-ubuntu .`
- Follow the Centos instructions

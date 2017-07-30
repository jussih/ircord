# Ircord

Discord to IRC to Discord bridge. Echoes chat between a Discord channel and an
IRC channel.

## Requirements

Tested with Elixir 1.4.5 and Erlang OTP 20.

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


# Centos

There is a premade Dockerfile for building a release for Centos 7.3.1611

- Build the Docker image `docker build -t centos-elixir:7.3.1611 .`
- Run a shell in the image, mapping your code directory inside the container 
  `docker run -it --rm -v $PWD:/usr/local/src/ircord centos-elixir:7.3.1611 /bin/bash`
- Inside the container:
  - `cd /usr/local/src/ircord`
  - `mix release.init`
  - `MIX_ENV=prod mix release --env=prod`
- The release will be built to `_build/prod/rel/ircord/releases/VERSION`


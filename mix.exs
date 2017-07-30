defmodule Ircord.Mixfile do
  use Mix.Project

  def project do
    [app: :ircord,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    # Distillery requires that all apps, even transitive dependencies, are
    # included in applications, or they will be left out of the release
    [
      extra_applications: [:logger],
      applications: [:discord_ex, :exirc, :dns, :kcl, :poison, :poly1305, :socket, :temp, :websocket_client],
      mod: {Ircord, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:discord_ex, git: "https://github.com/jussih/discord_ex.git", branch: "develop"},
      {:exirc, "~> 1.0.1"},
      {:distillery, "~> 1.0", runtime: false},
    ]
  end
end

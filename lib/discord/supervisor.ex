defmodule Ircord.Discord.Supervisor do
  use Supervisor

  @name Ircord.Discord.Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    discord_token = Application.get_env(:ircord, :discord_token)
    discord_config = %{
	    token: discord_token,
      handler: Ircord.DiscordBot,
    }
    children = [
      worker(DiscordEx.Client, [discord_config]),
      worker(DiscordEx.RestClient, [%{token: "Bot " <> discord_token}, [name: DiscordRESTClient]])
    ]

    supervise(children, strategy: :one_for_one)
  end


end

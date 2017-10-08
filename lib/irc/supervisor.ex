defmodule Ircord.IRC.Supervisor do
  use Supervisor

  @name Ircord.IRC.Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      worker(Ircord.IRC, [Application.get_env(:ircord, :irc_config), [name: IRC]]),
    ]

    supervise(children, strategy: :one_for_one)
  end


end

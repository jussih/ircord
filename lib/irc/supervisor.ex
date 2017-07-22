defmodule Ircord.Irc.Supervisor do
  use Supervisor

  @name Ircord.Irc.Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      worker(Ircord.IrcBot, [Application.get_env(:ircord, :irc_config), [name: IrcBot]]),
    ]

    supervise(children, strategy: :one_for_one)
  end


end

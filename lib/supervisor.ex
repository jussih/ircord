defmodule Ircord.Supervisor do
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Ircord.Bridge, [:bridge]),
      supervisor(Ircord.Discord.Supervisor, []),
      supervisor(Ircord.Irc.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end


end

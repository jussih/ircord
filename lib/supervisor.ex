defmodule Ircord.Supervisor do
  @moduledoc """
  Main process supervisor for bridge and slave supervisors for
  Discord and IRC
  """
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Ircord.Bridge, [:bridge]),
      supervisor(Ircord.Discord.Supervisor, []),
      supervisor(Ircord.IRC.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end


end

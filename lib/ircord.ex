defmodule Ircord do
  use Application

  def start(_type, _args) do
    Ircord.Supervisor.start_link()
  end
end

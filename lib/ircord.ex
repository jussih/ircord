defmodule Ircord do
  @moduledoc "Main application. Starts root supervisor."
  use Application

  def start(_type, _args) do
    Ircord.Supervisor.start_link()
  end
end

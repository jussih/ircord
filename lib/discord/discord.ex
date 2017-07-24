
defmodule Ircord.DiscordBot do
  @moduledoc """
  Discord bot client callback module. Based on the EchoBot example in
  the discord_ex library.
  """
  require Logger

  # Message Handler
  def handle_event({:message_create, payload}, state) do
    if payload.data["author"]["id"] != state[:client_id] do
      GenServer.call(:bridge, {:discord_message_received, _message_parser(payload)})
    end
    {:ok, state}
  end

  # Fallback Handler
  def handle_event({event, _payload}, state) do
    Logger.info "Received Event: #{event}"
    {:ok, state}
  end

  defp _message_parser(payload) do
    author_name = payload.data["author"]["username"]
    content  = payload.data["content"]
    mentions = payload.data["mentions"]
    expanded_content = Enum.reduce(mentions, content, fn(mention, msg) -> String.replace(msg, "<@" <> Integer.to_string(mention["id"]) <> ">", "@" <> mention["username"]) end)
    "<#{author_name}> #{expanded_content}"
  end
end

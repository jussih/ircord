defmodule Ircord.Discord.Message do
  @moduledoc "Message sending abstraction"

  alias DiscordEx.RestClient.Resources.Channel

  def send_message(rest_client, channel, sender, message) do
    msg = "<#{sender}> #{message}"
    Channel.send_message(rest_client, channel, %{content: msg})
  end
end

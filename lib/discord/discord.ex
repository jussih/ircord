
defmodule Ircord.DiscordBot do
  @moduledoc """
  Discord bot client callback module. Based on the EchoBot example in
  the discord_ex library.
  """
  require Logger

  # Message Handler
  def handle_event({:message_create, payload}, state) do
    if payload.data["author"]["id"] != state[:client_id] do
      GenServer.call(:bridge, {:discord_message_received, parse_payload_as_string(payload)})
    end
    {:ok, state}
  end

  # Fallback Handler
  def handle_event({event, _payload}, state) do
    Logger.info("Received Event: #{event}")
    {:ok, state}
  end

  defp parse_payload_as_string(payload) do
    payload.data["content"]
    |> add_author_tag_to_message(payload.data)
    |> expand_mentions_in_message(payload.data)
    |> add_attachment_urls_to_message(payload.data)
  end

  defp add_author_tag_to_message(message, payload_data) do
    "<#{payload_data["author"]["username"]}> #{message}"
  end

  defp expand_mentions_in_message(message, payload_data) do
    Enum.reduce(payload_data["mentions"], message, &replace_mention_id_in_message/2)
  end

  defp replace_mention_id_in_message(mention, message) do
    String.replace(message, "<@" <> Integer.to_string(mention["id"]) <> ">", "@" <> mention["username"])
  end
    
  defp add_attachment_urls_to_message(message, payload_data) do
    Enum.reduce(payload_data["attachments"], message, &add_one_attachment_url_to_message/2)
  end

  defp add_one_attachment_url_to_message(attachment, message) do
    case attachment["url"] do
      "" -> message
      url when is_binary(url) -> "#{message} [#{attachment["url"]}]"
      _ -> message
    end
  end
    
end

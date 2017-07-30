
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
    """
    TODO: get some info from file attachments
%{data: %{"attachments" => [%{"filename" => "cat.jpeg", "height" => 1163,
       "id" => 339078897423613952,
       "proxy_url" => "https://images.discordapp.net/attachments/321318083182460928/339078897423613952/cat.jpeg",
       "size" => 1160070,
       "url" => "https://cdn.discordapp.com/attachments/321318083182460928/339078897423613952/cat.jpeg",
       "width" => 2067}],
    "author" => %{"avatar" => "5dac354610b688fc5d7fe991b172f2b7",
      "discriminator" => "7512", "id" => 308968137678651393,
      "username" => "juba"}, "channel_id" => 321318083182460928,
    "content" => "comment", "edited_timestamp" => nil, "embeds" => [],
    "id" => 339078897910022145, "mention_everyone" => false,
    "mention_roles" => [], "mentions" => [], "nonce" => nil, "pinned" => false,
    "timestamp" => "2017-07-24T16:18:29.043000+00:00", "tts" => false,
    "type" => 0}, event_name: :MESSAGE_CREATE, op: :dispatch, seq_num: 17}
    """
    author_name = payload.data["author"]["username"]
    content  = payload.data["content"]
    mentions = payload.data["mentions"]
    expanded_content = Enum.reduce(mentions, content, fn(mention, msg) -> String.replace(msg, "<@" <> Integer.to_string(mention["id"]) <> ">", "@" <> mention["username"]) end)
    "<#{author_name}> #{expanded_content}"
  end
end

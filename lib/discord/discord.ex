
defmodule Ircord.DiscordBot do
  @moduledoc """
  Discord bot client callback module. Based on the EchoBot example in
  the discord_ex library.
  """
  require Logger

  alias DiscordEx.Client.Helpers.MessageHelper
  alias DiscordEx.RestClient.Resources.Channel

  # Message Handler
  def handle_event({:message_create, payload}, state) do
    spawn fn ->
      if payload.data["author"]["id"] != state[:client_id] do
        """
        TODO: payload with mention, use this to decode mention id to name
        %{data: %{"attachments" => [], "author" => %{"avatar" => "5dac354610b688fc5d7fe991b172f2b7", "discriminator" => "7512", "id" => 308968137678651393, "username" => "juba"}, "channel_id" => 321318083182460928, "content" => "<@321314936716525581>  wat", "edited_timestamp" => nil, "embeds" => [], "id" => 338301378277408770, "mention_everyone" => false, "mention_roles" => [], "mentions" => [%{"avatar" => nil, "bot" => true, "discriminator" => "5366", "id" => 321314936716525581, "username" => "kk-bot"}], "nonce" => "338301378130608128", "pinned" => false, "timestamp" => "2017-07-22T12:48:53.917000+00:00", "tts" => false, "type" => 0}, event_name: :MESSAGE_CREATE, op: :dispatch, seq_num: 11}
        """
        GenServer.call(:bridge, {:discord_message_received, _message_parser(payload)})
        if MessageHelper.actionable_message_for_me?(payload, state) do
          _command_parser(payload, state)
        end
      end
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
    "<#{author_name}> #{content}"
  end

  # Select command to execute based off message payload
  defp _command_parser(payload, state) do
    case MessageHelper.msg_command_parse(payload) do
      {nil, msg} ->
        Logger.info("do nothing for message #{msg}")
      {cmd, msg} ->
        _execute_command({cmd, msg}, payload, state)
    end
  end

  # Echo response back to user or channel
  defp _execute_command({"example:echo", message}, payload, state) do
    msg = String.upcase(message)
    Channel.send_message(state[:rest_client], payload.data["channel_id"], %{content: "#{msg} yourself!"})
  end

  # Pong response to ping
  defp _execute_command({"example:ping", _message}, payload, state) do
    Channel.send_message(state[:rest_client], payload.data["channel_id"], %{content: "Pong!"})
  end
end

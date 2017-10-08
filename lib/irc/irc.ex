
defmodule Ircord.IRC do
  @moduledoc """
  Irc presence for Ircord
  Based on the example bot implementation in the exirc library.
  """
  use GenServer
  require Logger

  defmodule Config do
    defstruct server:      nil,
              port:        nil,
              pass:        nil,
              nick:        nil,
              user:        nil,
              name:        nil,
              channel:     nil,
              channelpass: "",
              client:      nil

    def from_params(params) when is_map(params) do
      Enum.reduce(params, %Config{}, fn {k, v}, acc ->
        case Map.has_key?(acc, k) do
          true  -> Map.put(acc, k, v)
          false -> acc
        end
      end)
    end
  end

  alias ExIrc.Client
  alias ExIrc.SenderInfo
  alias Ircord.IRC.Messages

  def start_link(params, opts \\ []) when is_map(params) do
    config = Config.from_params(params)
    GenServer.start_link(__MODULE__, [config], opts)
  end

  def send_message(pid, sender, msg) do
    GenServer.call(pid, {:send_message, sender, msg})
  end

# GenServer callbacks

  def init([config]) do
    # Start the client and handler processes, the ExIrc supervisor is automatically started when your app runs
    {:ok, client}  = ExIrc.start_link!()

    # Register this process as the event handler with ExIrc
    Client.add_handler(client, self())

    # Connect and logon to a server, join a channel
    Logger.debug(fn -> "Connecting to #{config.server}:#{config.port}" end)
    Client.connect!(client, config.server, config.port)

    {:ok, %Config{config | :client => client}}
  end

  def handle_call({:send_message, sender, msg}, _from, config) do
    # IRC server will disconnect us if we flood too many chunked messages.
    # There should be some backoff here.
    Messages.from_string(sender, msg)
    |> Enum.each(fn message -> Client.msg(config.client, :privmsg, config.channel, message) end)
    {:reply, :ok, config}
  end

  def handle_info({:connected, server, port}, config) do
    Logger.debug(fn -> "Connected to #{server}:#{port}" end)
    Logger.debug(fn -> "Logging to #{server}:#{port} as #{config.nick}.." end)
    Client.logon(config.client, config.pass, config.nick, config.user, config.name)
    {:noreply, config}
  end

  def handle_info(:logged_in, config) do
    Logger.debug(fn -> "Logged in to #{config.server}:#{config.port}" end)
    Logger.debug(fn -> "Joining #{config.channel}.." end)
    Client.join(config.client, config.channel, config.channelpass)
    {:noreply, config}
  end

  def handle_info({:login_failed, :nickname_in_use}, config) do
    nick = Enum.map(1..8, fn x -> Enum.random('abcdefghijklmnopqrstuvwxyz') end)
    Client.nick(config.client, to_string(nick))
    {:noreply, config}
  end

  def handle_info(:disconnected, config) do
    Logger.debug(fn -> "Disconnected from #{config.server}:#{config.port}" end)
    {:stop, :normal, config}
  end

  def handle_info({:joined, channel}, config) do
    Logger.debug(fn -> "Joined #{channel}" end)
    {:noreply, config}
  end

  def handle_info({:names_list, channel, names_list}, config) do
    names = String.split(names_list, " ", trim: true)
            |> Enum.map(fn name -> " #{name}\n" end)
    Logger.info(fn -> "Users logged in to #{channel}:\n#{names}" end)
    {:noreply, config}
  end

  def handle_info({:received, msg, %SenderInfo{:nick => nick}, channel}, config) do
    Logger.debug(fn -> "#{nick} from #{channel}: #{msg}" end)
    Ircord.Bridge.handle_irc_message(:bridge, nick, msg)
    {:noreply, config}
  end

  def handle_info({:received, msg, %SenderInfo{:nick => nick}}, config) do
    Logger.warn(fn -> "#{nick}: #{msg}" end)
    reply = "Hi!"
    Client.msg(config.client, :privmsg, nick, reply)
    Logger.info(fn -> "Sent #{reply} to #{nick}" end)
    {:noreply, config}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, config) do
    {:noreply, config}
  end

  def terminate(_, state) do
    # Quit the channel and close the underlying client connection when the process is terminating
    Client.quit(state.client, "Quitting.")
    Client.stop!(state.client)
    :ok
  end
end


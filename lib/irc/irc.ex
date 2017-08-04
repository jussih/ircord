
defmodule Ircord.IrcBot do
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

  def start_link(params, opts \\ []) when is_map(params) do
    config = Config.from_params(params)
    GenServer.start_link(__MODULE__, [config], opts)
  end

# GenServer callbacks

  def init([config]) do
    # Start the client and handler processes, the ExIrc supervisor is automatically started when your app runs
    {:ok, client}  = ExIrc.start_link!()

    # Register this process as the event handler with ExIrc
    Client.add_handler(client, self())

    # Connect and logon to a server, join a channel
    Logger.debug("Connecting to #{config.server}:#{config.port}")
    Client.connect!(client, config.server, config.port)

    {:ok, %Config{config | :client => client}}
  end

  def handle_call({:send_message, msg}, _from, config) do
    Client.msg(config.client, :privmsg, config.channel, msg)
    {:reply, :ok, config}
  end

  def handle_info({:connected, server, port}, config) do
    Logger.debug("Connected to #{server}:#{port}")
    Logger.debug("Logging to #{server}:#{port} as #{config.nick}..")
    Client.logon(config.client, config.pass, config.nick, config.user, config.name)
    {:noreply, config}
  end

  def handle_info(:logged_in, config) do
    Logger.debug("Logged in to #{config.server}:#{config.port}")
    Logger.debug("Joining #{config.channel}..")
    Client.join(config.client, config.channel, config.channelpass)
    {:noreply, config}
  end

  def handle_info(:disconnected, config) do
    Logger.debug("Disconnected from #{config.server}:#{config.port}")
    {:stop, :normal, config}
  end

  def handle_info({:joined, channel}, config) do
    Logger.debug("Joined #{channel}")
    {:noreply, config}
  end

  def handle_info({:names_list, channel, names_list}, config) do
    names = String.split(names_list, " ", trim: true)
            |> Enum.map(fn name -> " #{name}\n" end)
    Logger.info("Users logged in to #{channel}:\n#{names}")
    {:noreply, config}
  end

  def handle_info({:received, msg, %SenderInfo{:nick => nick}, channel}, config) do
    Logger.debug("#{nick} from #{channel}: #{msg}")
    GenServer.call(:bridge, {:irc_message_received, "<#{nick}> #{msg}"})
    {:noreply, config}
  end

  def handle_info({:mentioned, msg, %SenderInfo{:nick => nick}, channel}, config) do
    Logger.warn("#{nick} mentioned you in #{channel}")
    case String.contains?(msg, "hi") do
      true ->
        reply = "Hi #{nick}!"
        Client.msg(config.client, :privmsg, config.channel, reply)
        Logger.info("Sent #{reply} to #{config.channel}")
      false ->
        :ok
    end
    {:noreply, config}
  end

  def handle_info({:received, msg, %SenderInfo{:nick => nick}}, config) do
    Logger.warn("#{nick}: #{msg}")
    reply = "Hi!"
    Client.msg(config.client, :privmsg, nick, reply)
    Logger.info("Sent #{reply} to #{nick}")
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


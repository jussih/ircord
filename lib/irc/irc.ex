
defmodule Ircord.IRC do
  @moduledoc """
  Irc presence for Ircord
  Based on the example bot implementation in the exirc library.
  """
  use GenServer
  require Logger

  defmodule State do
    defstruct server:        nil,
              port:          nil,
              pass:          nil,
              nick:          nil,
              user:          nil,
              name:          nil,
              channel:       nil,
              channelpass:   "",
              client:        nil,
              send_interval: 2000,
              send_queue:    :queue.new(),
              processing?:   false

    def from_params(params) when is_map(params) do
      Enum.reduce(params, %State{}, fn {k, v}, acc ->
        case Map.has_key?(acc, k) do
          true  -> Map.put(acc, k, v)
          false -> acc
        end
      end)
    end
  end

  alias ExIRC.Client
  alias ExIRC.SenderInfo
  alias Ircord.IRC.Messages

  def start_link(params, opts \\ []) when is_map(params) do
    state = State.from_params(params)
    GenServer.start_link(__MODULE__, [state], opts)
  end

  def send_message(pid, sender, msg) do
    GenServer.call(pid, {:send_message, sender, msg})
  end

# GenServer callbacks

  def init([state]) do
    # Start the client and handler processes, the ExIRC supervisor is automatically started when your app runs
    {:ok, client}  = ExIRC.start_link!()

    # Register this process as the event handler with ExIRC
    Client.add_handler(client, self())

    # Connect and logon to a server, join a channel
    Logger.debug(fn -> "Connecting to #{state.server}:#{state.port}" end)
    Client.connect!(client, state.server, state.port)

    {:ok, %State{state | :client => client}}
  end

  @doc """
  Server implementation of IRC message delivery.

  The message is chunked into smaller messages that will fit the limited message
  length of IRCNet. The chunks are queued and the queue is processed slowly to
  avoid being kicked from the server due to flood. Testing has showed that a
  slow interval of around 2000ms is required to avoid excess flood when big
  copypasta is sent from discord.
  """
  def handle_call({:send_message, sender, msg}, _from, %State{:send_queue => queue} = state) do
    messages = Messages.from_string(sender, msg)
    queue = Enum.reduce(messages, queue, fn (message, queue) -> :queue.in(message, queue) end)
    state = case state.processing? do
      true -> state
      false ->
        send(self(), :process_queue)
        %State{state | :processing? => true}
    end
    {:reply, :ok, %State{state | :send_queue => queue}}
  end

  def handle_info(:process_queue, state) do
    case :queue.out(state.send_queue) do
      {{:value, message}, queue} ->
        Client.msg(state.client, :privmsg, state.channel, message)
        Process.send_after(self(), :process_queue, state.send_interval)
        {:noreply, %State{state | :send_queue => queue}}
      {:empty, _queue} ->
        {:noreply, %State{state | :processing? => false}}
    end
  end

  # Event handlers for ExIRC from here on
  def handle_info({:connected, server, port}, state) do
    Logger.debug(fn -> "Connected to #{server}:#{port}" end)
    Logger.debug(fn -> "Logging to #{server}:#{port} as #{state.nick}.." end)
    Client.logon(state.client, state.pass, state.nick, state.user, state.name)
    {:noreply, state}
  end

  def handle_info(:logged_in, state) do
    Logger.debug(fn -> "Logged in to #{state.server}:#{state.port}" end)
    Logger.debug(fn -> "Joining #{state.channel}.." end)
    Client.join(state.client, state.channel, state.channelpass)
    {:noreply, state}
  end

  def handle_info({:login_failed, :nick_in_use}, state) do
    nick = Enum.map(1..8, fn -> Enum.random('abcdefghijklmnopqrstuvwxyz') end)
    Client.nick(state.client, to_string(nick))
    {:noreply, state}
  end

  def handle_info(:disconnected, state) do
    Logger.debug(fn -> "Disconnected from #{state.server}:#{state.port}" end)
    {:stop, :normal, state}
  end

  def handle_info({:joined, channel}, state) do
    Logger.debug(fn -> "Joined #{channel}" end)
    {:noreply, state}
  end

  def handle_info({:names_list, channel, names_list}, state) do
    names = String.split(names_list, " ", trim: true)
            |> Enum.map(fn name -> " #{name}\n" end)
    Logger.info(fn -> "Users logged in to #{channel}:\n#{names}" end)
    {:noreply, state}
  end

  def handle_info({:received, msg, %SenderInfo{:nick => nick}, channel}, state) do
    Logger.debug(fn -> "#{nick} from #{channel}: #{msg}" end)
    Ircord.Bridge.handle_irc_message(:bridge, nick, msg)
    {:noreply, state}
  end

  def handle_info({:received, msg, %SenderInfo{:nick => nick}}, state) do
    Logger.warn(fn -> "#{nick}: #{msg}" end)
    reply = "Hi!"
    Client.msg(state.client, :privmsg, nick, reply)
    Logger.info(fn -> "Sent #{reply} to #{nick}" end)
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_, state) do
    # Quit the channel and close the underlying client connection when the process is terminating
    Client.quit(state.client, "Quitting.")
    Client.stop!(state.client)
    :ok
  end
end


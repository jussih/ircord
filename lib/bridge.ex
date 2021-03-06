defmodule Ircord.Bridge do
  @moduledoc """
  Bridge between IRC and Discord. Echoes messages between networks.
  """

  use GenServer  # implements the GenServer behaviour
  require Logger

  ## Client API
  # these functions are called from elsewhere to talk to our server
  # they are executed in the calling process

  @doc """
  Starts the bridge server.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  def handle_discord_message(bridge, sender, message) do
    GenServer.call(bridge, {:discord_message_received, sender, message})
  end

  def handle_irc_message(bridge, sender, message) do
    GenServer.call(bridge, {:irc_message_received, sender, message})
  end

  ## Server Callbacks
  # the GenServer implementation in OTP calls these functions to modify
  # the server state when it receives messages
  # they are executed in the server process

  @doc """
  Init is called when GenServer.start_link() starts the server process
  """
  def init(:ok) do
    {:ok, %{discord_channel: Application.get_env(:ircord, :discord_channel)}}
  end

  @doc """
  handle_call() is called when the server receives a synchronous message
  a reply is required, which is returned to the caller
  state parameter is the current server state. callback can create a new state
  when handling messages and pass that back to the server
  """
  def handle_call({:discord_message_received, sender, message}, _from, state) do
    Logger.debug(fn -> "Discord message received from #{sender}: #{message}" end)
    Ircord.IRC.send_message(IRC, sender, message)
    {:reply, :ok, state}
  end

  def handle_call({:irc_message_received, sender, message}, _from, state) do
    Logger.debug(fn -> "IRC message received from #{sender}: #{message}" end)
    Ircord.Discord.Message.send_message(DiscordRESTClient, state.discord_channel, sender, message)
    {:reply, :ok, state}
  end

  @doc """
  handle_cast() is called when the server receives an asynchronous message
  no reply is returned and the caller does not block.
  """
  def handle_cast(_msg, state) do
    {:noreply, state}
  end

end


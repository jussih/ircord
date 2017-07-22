defmodule Ircord.Bridge do
  use GenServer  # implements the GenServer behaviour
  require Logger
  alias DiscordEx.RestClient.Resources.Channel

  ## Client API
  # these functions are called from elsewhere to talk to our server
  # they are executed in the calling process

  @doc """
  Starts the bridge server.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  @doc """
  Send a message to discord
  """
  def send_to_discord(sender, msg, channel) do
    # need to know the discord channel id, which is probably globally unique
    # so guild id is not needed
    {:ok}
  end

  def send_irc(bridge, msg) do
    GenServer.call(bridge, {:send_irc, msg})
  end


  ## Server Callbacks
  # the GenServer implementation in OTP calls these functions to modify
  # the server state when it receives messages
  # they are executed in the server process

  @doc """
  Init is called when GenServer.start_link() starts the server process
  """
  def init(:ok) do
    # start the discord client process
    discord_token = Application.get_env(:ircord, :discord_token)
    {:ok, discord_bot} = DiscordEx.Client.start_link(%{
	    token: discord_token,
      handler: Ircord.DiscordBot,
    })
    {:ok, discord_rest_client} = DiscordEx.RestClient.start_link(%{token: discord_token})

    irc_config = Application.get_env(:ircord, :irc_config)
    {:ok, irc_bot} = Ircord.IrcBot.start_link(irc_config)
    {:ok, %{discord_client: discord_bot, irc_client: irc_bot,
      discord_channel: Application.get_env(:ircord, :discord_channel),
      discord_rest_client: discord_rest_client}}
  end

  @doc """
  handle_call() is called when the server receives a synchronous message
  a reply is required, which is returned to the caller
  state parameter is the current server state. callback can create a new state
  when handling messages and pass that back to the server
  """
  def handle_call({:discord_message_received, message}, _from, state) do
    Logger.info("Discord message received: #{message}")
    send_irc_message(message, state)
    {:reply, :ok, state}
  end

  def handle_call({:irc_message_received, message}, _from, state) do
    Logger.info("IRC message received: #{message}")
    send_discord_message(message, state)
    {:reply, :ok, state}
  end

  def handle_call({:send_irc, msg}, _from, state) do
    reply = send_irc_message(msg, state)
    {:reply, reply, state}
  end

  def handle_call({:send_discord, msg}, _from, state) do
    reply = send_discord_message(msg, state)
    {:reply, :ok, state}
  end

  @doc """
  handle_cast() is called when the server receives an asynchronous message
  no reply is returned and the caller does not block.
  """
  def handle_cast(msg, state) do
    {:noreply, state}
  end

  defp send_irc_message(msg, state) do
    GenServer.call(state.irc_client, {:send_message, msg})
  end

  defp send_discord_message(msg, state) do
    Channel.send_message(state.discord_rest_client, state.discord_channel, %{content: msg})
  end

end


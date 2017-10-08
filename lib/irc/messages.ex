defmodule Ircord.IRC.Messages do
  @moduledoc """
  IRC message helper. Long strings must be sent in multiple messages.
  """
  def from_string(sender, string) do
    string
    |> String.split("\n", trim: true)
    |> Enum.map(fn msg -> chunk_msg(msg, 410) end)  # RFC 1459: max length 510 + CRLF
    |> List.flatten()
    |> Enum.map(fn msg -> "<#{sender}> #{msg}" end)
  end

  defp chunk_msg("", _size), do: []
  defp chunk_msg(string, size) do
    {chunk, tail} = String.split_at(string, size)
    [chunk, chunk_msg(tail, size)]
  end
end

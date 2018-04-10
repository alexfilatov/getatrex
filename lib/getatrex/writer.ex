defmodule Getatrex.Writer do
  @moduledoc """
  Module responsible for writing translations to a file
  Usage:
    1. Start the generic server by Getatrex.Writer.start_link(filename)
      where the filename if the name of the file you are going to write data
    2. Send messages to server with payload you need to write to a file:
      Getatrex.Writer.write(payload)
      where payload could be simple string or %Getatrex.Message{} struct
  """
  require Logger
  use GenServer

  def start_link(filename) do
    GenServer.start_link(__MODULE__, %{filename: filename, file_pointer: File.open!(filename, [:write])}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Write translated struct to disctionary
  adds new line in the beginning of the struct
  """
  def write(%Getatrex.Message{} = message) do
    :ok = GenServer.call(__MODULE__, {:write_message, message})
  end

  def write(line) do
    :ok = GenServer.call(__MODULE__, {:write_line, line})
  end

  def handle_call({:write_message, %{mentions: mentions, msgid: msgid, msgstr: msgstr}}, _from, state)
  when mentions == [] or is_nil(mentions) do
    message_string = [
      ~s(msgid "#{msgid}"),
      ~s(msgstr "#{msgstr}")
    ]
    |> Enum.join("\n")

    IO.write(state[:file_pointer], message_string <> "\n\n")

    {:reply, :ok, state}
  end

  def handle_call({:write_message, %{mentions: mentions, msgid: msgid, msgstr: msgstr}}, _from, state) do
    message_list = [
      mentions_string(mentions),
      ~s(msgid "#{msgid}"),
      ~s(msgstr "#{msgstr}")
    ]

    message_string = message_list |> Enum.join("\n")
    IO.write(state[:file_pointer], message_string <> "\n\n")

    {:reply, :ok, state}
  end

  def handle_call({:write_message, message}, _from, state) do
    {:reply, {:error, message}, state}
  end

  def handle_call({:write_line, line}, _from, state) do
    {:reply, IO.write(state[:file_pointer], String.trim(line) <> "\n"), state}
  end

  defp mentions_string(mentions) do
    mentions |> Enum.join("\n")
  end

end

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
  use GenServer

  def start_link(filename) do
    GenServer.start_link(__MODULE__, %{filename: filename, file_pointer: File.open!(filename, [:append])}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def write(%Getatrex.Message{} = message) do

  end

  def write(line) do
    :ok = GenServer.call(__MODULE__, {:write, line})
  end

  def handle_call({:write, line}, _from, state) do
    {:reply, File.write(state[:filename], line), state}
  end

end

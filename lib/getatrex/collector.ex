defmodule Getatrex.Collector do
  @moduledoc """
  GenServer
  Collects lines, creates a Message, runs translation, writes to file
  """
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %Getatrex.Message{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  # API
  def dispatch_line(line) do
    GenServer.cast(__MODULE__, {:dispatch_line, line})
  end

  # SERVER
  def handle_cast({:dispatch_line, "##" <> tail = line}, state) do
    IO.puts "A comment: #{line}"
    {:noreply, state}
  end

  def handle_cast({:dispatch_line, "#:" <> tail}, state) do
    {:noreply, Map.put(state, :mentions, Map.get(state, :mentions) ++ ["#:" <> tail])}
  end

  def handle_cast({:dispatch_line, ~s(msgid "") <> tail}, state) do
    IO.puts "An empty msgid"
    {:noreply, state}
  end

  def handle_cast({:dispatch_line, ~s(msgid ) <> tail = line}, state) do
    IO.puts "Message to translate: #{line}"
    {:noreply, state}
  end

  def handle_cast({:dispatch_line, ~s(msgstr "") <> tail}, state) do
    IO.puts "An empty translation"
    {:noreply, state}
  end

  def handle_cast({:dispatch_line, line}, state) do
    Getatrex.Writer.write(line)
    {:noreply, state}
  end

end

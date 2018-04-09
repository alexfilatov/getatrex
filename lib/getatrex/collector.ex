defmodule Getatrex.Collector do
  @moduledoc """
  GenServer
  Collects lines, creates a Message, runs translation, writes to file
  """
  require Logger
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
  def handle_cast({:dispatch_line, "" = line}, state) do
    Getatrex.Writer.write(line)
    {:noreply, %Getatrex.Message{}}
  end

  def handle_cast({:dispatch_line, "##" <> _tail = line}, state) do
    IO.puts "A comment: #{line}"
    Getatrex.Writer.write(line)
    {:noreply, state}
  end

  def handle_cast({:dispatch_line, "#:" <> _tail = line}, state) do
    # IO.inspect state
    {:noreply, Map.put(state, :mentions, Map.get(state, :mentions) ++ [line])}
  end

  def handle_cast({:dispatch_line, ~s(msgid "") <> _tail = line}, state) do
    # IO.inspect state
    Getatrex.Writer.write(line)
    {:noreply, %Getatrex.Message{}}
  end

  def handle_cast({:dispatch_line, ~s(msgid ) <> tail}, state) do
    [[_, msgid]] = Regex.scan(~r/"(.*?)"/, tail)
    {:noreply, Map.put(state, :msgid, msgid)}
  end

  def handle_cast({:dispatch_line, ~s(msgstr "") <> _tail = line}, %{msgid: nil} = state) do
    Getatrex.Writer.write(line)
    {:noreply, state}
  end

  def handle_cast({:dispatch_line, ~s(msgstr "") <> _tail}, %{msgid: msgid} = state) do
    translated_string = case Getatrex.Translator.Google.translate_to_locale(msgid, "de") do
      {:ok, translated_string} -> translated_string
      {:error, error} ->
        Logger.error "Cannot translate [#{msgid}]. Reason: #{inspect error}"
        ""
    end

    {:noreply, Map.put(state, :msgstr, translated_string)}
  end

  def handle_cast({:dispatch_line, line}, state) do
    Getatrex.Writer.write(line)
    {:noreply, state}
  end

end

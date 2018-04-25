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
    # starting Goth
    {:ok, _started} = Application.ensure_all_started(:goth)

    {:ok, state}
  end

  # API
  def dispatch_line(line) do
    :ok = GenServer.call(__MODULE__, {:dispatch_line, String.trim(line)})
  end

  # SERVER
  def handle_call({:dispatch_line, "" = line}, _from, %{msgid: nil, msgstr: nil} = state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, %Getatrex.Message{}}
  end

  def handle_call({:dispatch_line, "" = line}, _from, %{msgid: msgid, msgstr: msgstr} = state) do
    Getatrex.Writer.write(state)
    {:reply, :ok, %Getatrex.Message{}}
  end

  def handle_call({:dispatch_line, "##" <> _tail = line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

  def handle_call({:dispatch_line, "#:" <> _tail = line}, _from, state) do
    {:reply, :ok, Map.put(state, :mentions, Map.get(state, :mentions) ++ [line])}
  end

  def handle_call({:dispatch_line, ~s(msgid "") <> _tail = line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, %Getatrex.Message{}}
  end

  def handle_call({:dispatch_line, ~s(msgid ) <> tail}, _from, state) do
    [[_, msgid]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgid, msgid)}
  end

  def handle_call({:dispatch_line, ~s(msgstr "") <> _tail = line}, _from, %{msgid: nil} = state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

  # TODO: removed hardcoded lang
  def handle_call({:dispatch_line, ~s(msgstr "") <> _tail}, _from, %{msgid: msgid} = state) do
    translated_string =
      case String.trim(msgid) |> Getatrex.Translator.Google.translate_to_locale("de") do
        {:ok, translated_string} -> translated_string
        {:error, error} ->
          Logger.error "Cannot translate [#{msgid}]. Reason: #{inspect error}"
          ""
      end

    {:reply, :ok, Map.put(state, :msgstr, translated_string)}
  end

  def handle_call({:dispatch_line, line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

end

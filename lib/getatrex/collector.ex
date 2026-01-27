defmodule Getatrex.Collector do
  @moduledoc """
  GenServer
  Collects lines, creates a Message, runs translation, writes to file
  """
  require Logger
  use GenServer

  def start_link(to_lang) do
    GenServer.start_link(__MODULE__, %Getatrex.Message{to_lang: to_lang}, name: __MODULE__)
  end

  def init(state) do
    translator = Application.get_env(:getatrex, :translator, Getatrex.Translator.Google)

    if translator == Getatrex.Translator.Google do
      {:ok, _started} = Application.ensure_all_started(:goth)
    end

    {:ok, state}
  end

  # API
  def dispatch_line(line) do
    :ok = GenServer.call(__MODULE__, {:dispatch_line, String.trim(line)})
  end

  # SERVER
  def handle_call({:dispatch_line, "" = _line}, _from, %{msgid: nil, msgstr: nil} = state) do
    Getatrex.Writer.write("")
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang}}
  end

  def handle_call({:dispatch_line, "" = _line}, _from, %{msgid: _msgid, msgstr: _msgstr} = state) do
    Getatrex.Writer.write(state)
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang}}
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
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang}}
  end

  def handle_call({:dispatch_line, ~s(msgstr "") <> _tail = line}, _from, %{msgid: nil} = state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

  def handle_call({:dispatch_line, ~s(msgid ) <> tail}, _from, state) do
    [[_, msgid]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgid, msgid)}
  end

  def handle_call({:dispatch_line, ~s(msgstr "") <> _tail}, _from, %{msgid: msgid} = state) do
    translator = Application.get_env(:getatrex, :translator, Getatrex.Translator.Google)

    translated_string =
      case Getatrex.Placeholder.prepare(msgid)
           |> translator.translate_to_locale(state.to_lang) do
        {:ok, translated_string} -> Getatrex.Placeholder.restore(translated_string)
        {:error, error} ->
          Logger.error "Cannot translate [#{msgid}]. Reason: #{inspect error}"
          ""
      end

    {:reply, :ok, Map.put(state, :msgstr, translated_string)}
  end

  def handle_call({:dispatch_line, ~s(msgstr ) <> tail}, _from, %{msgid: _msgid} = state) do
    [[_, msgstr]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgstr, msgstr)}
  end

  def handle_call({:dispatch_line, line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

end

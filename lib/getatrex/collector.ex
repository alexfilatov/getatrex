defmodule Getatrex.Collector do
  @moduledoc """
  GenServer
  Collects lines, creates a Message, runs translation, writes to file
  """
  require Logger
  use GenServer

  def start_link(to_lang) do
    start_link(to_lang, :post, nil)
  end

  def start_link(to_lang, request_mode, api_key) do
    GenServer.start_link(__MODULE__, %Getatrex.Message{to_lang: to_lang, request_mode: request_mode, api_key: api_key}, name: __MODULE__)
  end

  def init(state) do
    # starting Hackney and Goth
    {:ok, _started} = Application.ensure_all_started(:hackney)
    {:ok, _started} = Application.ensure_all_started(:goth)

    {:ok, state}
  end

  # API
  def dispatch_line(line) do
    :ok = GenServer.call(__MODULE__, {:dispatch_line, String.trim(line)})
  end

  # SERVER
  @doc """
  Writes simple line if
  """
  def handle_call({:dispatch_line, "" = line}, _from, %{msgid: nil, msgstr: nil} = state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang, request_mode: state.request_mode, api_key: state.api_key}}
  end

  @doc """
  Writes translated message struct to file
  """
  def handle_call({:dispatch_line, "" = line}, _from, %{msgid: msgid, msgstr: msgstr} = state) do
    Getatrex.Writer.write(state)
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang, request_mode: state.request_mode, api_key: state.api_key}}
  end

  @doc """
  Writes comment
  """
  def handle_call({:dispatch_line, "##" <> _tail = line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

  @doc """
  Writes mention
  """
  def handle_call({:dispatch_line, "#:" <> _tail = line}, _from, state) do
    {:reply, :ok, Map.put(state, :mentions, Map.get(state, :mentions) ++ [line])}
  end

  @doc """
  Empty message ID
  """
  def handle_call({:dispatch_line, ~s(msgid "") <> _tail = line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang, request_mode: state.request_mode, api_key: state.api_key}}
  end

  def handle_call({:dispatch_line, ~s(msgstr "") <> _tail = line}, _from, %{msgid: nil} = state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

  def handle_call({:dispatch_line, ~s(msgid ) <> tail}, _from, state) do
    [[_, msgid]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgid, msgid)}
  end

# Plural empty
  def handle_call({:dispatch_line, ~s(msgid_plural "") <> _tail = line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, %Getatrex.Message{to_lang: state.to_lang, request_mode: state.request_mode, api_key: state.api_key}}
  end

# Plural
  def handle_call({:dispatch_line, ~s(msgid_plural ) <> tail}, _from, state) do
    [[_, msgid_plural]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgid_plural, msgid_plural)}
  end

# original msgstr
  def handle_call({:dispatch_line, ~s(msgstr "") <> _tail}, _from, %{msgid: msgid} = state) do
    translated_string =
      case prepare_string(msgid) |> Getatrex.Translator.Google.translate_to_locale(state.to_lang, state.request_mode, state.api_key) do
        {:ok, translated_string} -> revert_string(translated_string)
        {:error, error} ->
          Logger.error "Cannot translate [#{msgid}]. Reason: #{inspect error}"
          ""
      end

    {:reply, :ok, Map.put(state, :msgstr, translated_string)}
  end

# msgstr[1]
  def handle_call({:dispatch_line, ~s(msgstr[1] "") <> _tail}, _from, %{msgid_plural: msgid_plural} = state) do
    translated_string =
      case prepare_string(msgid_plural) |> Getatrex.Translator.Google.translate_to_locale(state.to_lang, state.request_mode, state.api_key) do
        {:ok, translated_string} -> revert_string(translated_string)
        {:error, error} ->
          Logger.error "Cannot translate [#{msgid_plural}]. Reason: #{inspect error}"
          ""
      end

    {:reply, :ok, Map.put(state, :msgstr1, translated_string)}
  end

# msgstr[0]
  def handle_call({:dispatch_line, ~s(msgstr[0] "") <> _tail}, _from, %{msgid: msgid} = state) do
    translated_string =
      case prepare_string(msgid) |> Getatrex.Translator.Google.translate_to_locale(state.to_lang, state.request_mode, state.api_key) do
        {:ok, translated_string} -> revert_string(translated_string)
        {:error, error} ->
          Logger.error "Cannot translate [#{msgid}]. Reason: #{inspect error}"
          ""
      end

    {:reply, :ok, Map.put(state, :msgstr0, translated_string)}
  end

# original msgstr
  def handle_call({:dispatch_line, ~s(msgstr ) <> tail}, _from, %{msgid: msgid} = state) do
    [[_, msgstr]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgstr, msgstr)}
  end

# msgstr0
  def handle_call({:dispatch_line, ~s(msgstr[0] ) <> tail}, _from, %{msgid: msgid} = state) do
    [[_, msgstr0]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgstr0, msgstr0)}
  end
# msgstr1
  def handle_call({:dispatch_line, ~s(msgstr[1] ) <> tail}, _from, %{msgid: msgid} = state) do
    [[_, msgstr1]] = Regex.scan(~r/^"(.*?)"$/, tail)
    {:reply, :ok, Map.put(state, :msgstr1, msgstr1)}
  end

# -----------------

  # def handle_call({:dispatch_line, ~s(msgstr[0] "") <> _tail}, _from, %{msgid: msgid} = state) do
  #   translated_string =
  #     case prepare_string(msgid) |> Getatrex.Translator.Google.translate_to_locale(state.to_lang, state.request_mode, state.api_key) do
  #       {:ok, translated_string} -> revert_string(translated_string)
  #       {:error, error} ->
  #         Logger.error "Cannot translate [#{msgid}]. Reason: #{inspect error}"
  #         ""
  #     end

  #   {:reply, :ok, Map.put(state, :msgstr0, translated_string)}
  # end

  # def handle_call({:dispatch_line, ~s(msgstr[0] ) <> tail}, _from, %{msgid: msgid} = state) do
  #  [[_, msgstr]] = Regex.scan(~r/^"(.*?)"$/, tail)
  #   {:reply, :ok, Map.put(state, :msgstr0, msgstr)}
  # end

# -----------------

  def handle_call({:dispatch_line, line}, _from, state) do
    Getatrex.Writer.write(line)
    {:reply, :ok, state}
  end

  defp prepare_string(str) do
    str
    |> String.trim()
    # Doing a magic like this because Google Translate translates vars
    # and we don't want that:
    |> (&(Regex.replace(~r/%{(.*?)}/, &1, fn _, x -> "BASE64ENCODE_VARIABLE[#{Base.encode64(x, padding: false)}]" end))).()
    |> (&(Regex.replace(~r/"/, &1, fn(_, x) -> " GETATREX_DOUBLE_QUOTE " end))).()
  end

  defp revert_string(str) do
    str
    |> (&(Regex.replace(~r/BASE64ENCODE_VARIABLE\s*\[([^\]]+)\]*/, &1, fn(_, x) -> "%{#{Base.decode64!(x, padding: false)}}" end))).()
    |> (&(Regex.replace(~r/\sGETATREX_DOUBLE_QUOTE\s/, &1, fn(_, x) -> "\"" end))).()
  end

end

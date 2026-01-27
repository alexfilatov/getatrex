defmodule Getatrex.PO do
  @moduledoc """
  Translates `.po` files using Expo's parser and composer.
  """

  alias Expo.{Message, Messages, PO}
  require Logger

  @type stats :: %{
          total: non_neg_integer(),
          translated: non_neg_integer(),
          skipped: non_neg_integer(),
          errors: non_neg_integer(),
          cached: non_neg_integer()
        }

  @spec translate_file(Path.t(), Path.t(), String.t(), keyword()) :: {:ok, stats()} | {:error, term()}
  def translate_file(source_path, target_path, to_lang, opts \\ []) do
    translator = Keyword.get(opts, :translator, Getatrex.Translator.Google)

    if translator == Getatrex.Translator.Google do
      {:ok, _started} = Application.ensure_all_started(:goth)
    end

    with {:ok, messages} <- PO.parse_file(source_path) do
      {translated_messages, _cache, stats} =
        translate_messages(messages.messages, to_lang, opts)

      translated = %Messages{messages | messages: translated_messages}

      File.write!(target_path, PO.compose(translated))

      {:ok, stats}
    end
  end

  defp translate_messages(messages, to_lang, opts) do
    Enum.reduce(messages, {[], %{}, empty_stats()}, fn message, {acc, cache, stats} ->
      stats = bump(stats, :total)
      {message, cache, stats} = translate_message(message, to_lang, cache, stats, opts)
      {[message | acc], cache, stats}
    end)
    |> reverse_acc()
  end

  defp reverse_acc({messages, cache, stats}), do: {Enum.reverse(messages), cache, stats}

  defp translate_message(%Message.Singular{obsolete: true} = message, _to_lang, cache, stats, _opts) do
    {message, cache, stats}
  end

  defp translate_message(%Message.Singular{} = message, to_lang, cache, stats, opts) do
    msgid = message.msgid |> IO.iodata_to_binary()

    cond do
      blank?(msgid) ->
        {message, cache, bump(stats, :skipped)}

      not empty_msgstr?(message.msgstr) ->
        {message, cache, bump(stats, :skipped)}

      true ->
        {result, cache, stats} = translate_text(msgid, message.msgctxt, to_lang, cache, stats, opts)

        case result do
          {:ok, translated} ->
            message = %Message.Singular{message | msgstr: [translated]}
            {message, cache, bump(stats, :translated)}

          {:error, reason} ->
            Logger.error("Cannot translate [#{msgid}]. Reason: #{inspect(reason)}")
            {message, cache, bump(stats, :errors)}
        end
    end
  end

  defp translate_message(%Message.Plural{obsolete: true} = message, _to_lang, cache, stats, _opts) do
    {message, cache, stats}
  end

  defp translate_message(%Message.Plural{} = message, to_lang, cache, stats, opts) do
    msgid = message.msgid |> IO.iodata_to_binary()
    msgid_plural = message.msgid_plural |> IO.iodata_to_binary()

    cond do
      blank?(msgid) ->
        {message, cache, bump(stats, :skipped)}

      not needs_plural_translation?(message) ->
        {message, cache, bump(stats, :skipped)}

      true ->
        {message, cache, stats} =
          translate_plural_message(message, msgid, msgid_plural, to_lang, cache, stats, opts)

        {message, cache, stats}
    end
  end

  defp translate_plural_message(message, msgid, msgid_plural, to_lang, cache, stats, opts) do
    indexes = message.msgstr |> Map.keys() |> Enum.sort()
    indexes = if indexes == [], do: [0, 1], else: indexes

    {singular_result, cache, stats} =
      translate_text(msgid, message.msgctxt, to_lang, cache, stats, opts)

    {plural_result, cache, stats} =
      translate_text(msgid_plural, message.msgctxt, to_lang, cache, stats, opts)

    case {singular_result, plural_result} do
      {{:ok, singular}, {:ok, plural}} ->
        msgstr =
          Enum.reduce(indexes, message.msgstr, fn index, acc ->
            value = if index == 0, do: singular, else: plural

            if empty_msgstr?(Map.get(acc, index, [""])) do
              Map.put(acc, index, [value])
            else
              acc
            end
          end)

        message = %Message.Plural{message | msgstr: msgstr}
        {message, cache, bump(stats, :translated)}

      {_, _} ->
        {message, cache, bump(stats, :errors)}
    end
  end

  defp translate_text(text, msgctxt, to_lang, cache, stats, opts) do
    text = text |> String.trim()

    if text == "" do
      {{:ok, ""}, cache, stats}
    else
      prepared = Getatrex.Placeholder.prepare(text)
      format = resolve_format(text, opts)
      context = (msgctxt || []) |> IO.iodata_to_binary() |> String.trim()
      key = {to_lang, format, context, prepared}

      case cache do
        %{^key => cached} ->
          {{:ok, cached}, cache, bump(stats, :cached)}

        _ ->
          translator = Keyword.get(opts, :translator, Application.get_env(:getatrex, :translator, Getatrex.Translator.Google))
          translator_opts = merge_translator_opts(opts, format)

          case translator.translate_to_locale(prepared, to_lang, translator_opts) do
            {:ok, translated} ->
              translated = Getatrex.Placeholder.restore(translated)
              {{:ok, translated}, Map.put(cache, key, translated), stats}

            {:error, reason} ->
              {{:error, reason}, cache, stats}
          end
      end
    end
  end

  defp merge_translator_opts(opts, format) do
    config_opts = Application.get_env(:getatrex, :google_translate, [])
    call_opts = Keyword.get(opts, :translator_opts, [])

    config_opts
    |> Keyword.merge(call_opts)
    |> Keyword.put(:format, format)
  end

  defp blank?(text), do: String.trim(text) == ""

  defp empty_msgstr?(msgstr) when is_list(msgstr), do: msgstr |> IO.iodata_to_binary() |> blank?()
  defp empty_msgstr?(msgstr) when is_binary(msgstr), do: blank?(msgstr)

  defp needs_plural_translation?(%Message.Plural{msgstr: msgstr}) do
    msgstr == %{} or Enum.any?(msgstr, fn {_index, value} -> empty_msgstr?(value) end)
  end

  defp resolve_format(text, opts) do
    config_format =
      Application.get_env(:getatrex, :google_translate, [])
      |> Keyword.get(:format)

    format =
      opts
      |> Keyword.get(:format,
        Keyword.get(Keyword.get(opts, :translator_opts, []), :format, config_format)
      )
      |> normalize_format()

    case format do
      "html" -> "html"
      "text" -> "text"
      _ -> if html?(text), do: "html", else: "text"
    end
  end

  defp normalize_format(nil), do: nil
  defp normalize_format(:auto), do: nil
  defp normalize_format(:html), do: "html"
  defp normalize_format(:text), do: "text"
  defp normalize_format(format) when is_binary(format), do: String.downcase(format)

  defp html?(text), do: Regex.match?(~r/<[^>]+>/, text)

  defp bump(stats, key), do: Map.update!(stats, key, &(&1 + 1))

  defp empty_stats do
    %{total: 0, translated: 0, skipped: 0, errors: 0, cached: 0}
  end
end

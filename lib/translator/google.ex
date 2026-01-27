defmodule Getatrex.Translator.Google do
  @moduledoc """
  Implementation of gcloudex google translator
  """
  @endpoint "https://translation.googleapis.com/language/translate/v2"

  def translate_to_locale(text, locale), do: translate_to_locale(text, locale, [])

  def translate_to_locale("", _locale, _opts), do: {:ok, ""}

  def translate_to_locale(text, locale, opts) when is_binary(text) do
    case translate_to_locale([text], locale, opts) do
      {:ok, [translated | _]} -> {:ok, translated}
      {:error, reason} -> {:error, reason}
    end
  end

  def translate_to_locale(texts, locale, opts) when is_list(texts) do
    body =
      %{q: texts, target: locale, format: normalize_format(Keyword.get(opts, :format, "text"))}
      |> maybe_put_model(opts)
      |> Jason.encode!()

    endpoint = Keyword.get(opts, :endpoint, @endpoint)
    {:ok, token} = resolve_token(opts)

    headers = [
      {"Authorization", "Bearer #{token.token}"},
      {"Content-Type", "application/json"}
    ]

    http_opts = Keyword.get(opts, :http_opts, [])
    http_client = Keyword.get(opts, :http_client, &HTTPoison.post/4)

    case http_client.(endpoint, body, headers, http_opts) do
      {:ok, %{status_code: code, body: body}} when code in 200..299 ->
        translated_texts(Jason.decode!(body))

      {:ok, %{body: body}} ->
        translated_texts(Jason.decode!(body))

      error ->
        {:error, "Error during request API #{inspect(error)}"}
    end
  end

  defp translated_texts(%{"data" => %{"translations" => translations}}) do
    {:ok, Enum.map(translations, & &1["translatedText"])}
  end

  defp translated_texts(%{"error" => %{"code" => code, "message" => message}}) do
    {:error, "Error #{code}: #{message}"}
  end

  defp translated_texts(_response), do: {:error, "Unexpected response from translation API"}

  defp normalize_format(format) when is_binary(format), do: String.downcase(format)
  defp normalize_format(:html), do: "html"
  defp normalize_format(:text), do: "text"
  defp normalize_format(_), do: "text"

  defp maybe_put_model(body, opts) do
    case Keyword.get(opts, :model) do
      nil -> body
      model -> Map.put(body, :model, model)
    end
  end

  defp resolve_token(opts) do
    case Keyword.get(opts, :token) do
      nil ->
        Goth.Token.fetch(scopes: ["https://www.googleapis.com/auth/cloud-platform"])

      %Goth.Token{} = token ->
        {:ok, token}

      token when is_binary(token) ->
        {:ok, %{token: token}}
    end
  end
end

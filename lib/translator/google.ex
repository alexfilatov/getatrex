defmodule Getatrex.Translator.Google do
  @moduledoc """
  Implementation of gcloudex google translator
  """
  alias Goth.Token
  @endpoint  "https://translation.googleapis.com/language/translate/v2"

  def translate_to_locale("", _), do: {:ok, ""}

  def translate_to_locale(text, locale) do
    body = %{q: text, target: locale, format: "text"} |> Jason.encode!()
    {:ok, token} = Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    headers = [{"Authorization", "Bearer #{token.token}"}]

    case HTTPoison.post(@endpoint, body, headers) do
      {:ok, %{body: body}} -> translated_text(Jason.decode!(body))
      error -> {:error, "Error during request API #{inspect error}"}
    end
  end

  defp translated_text(%{"data" => %{"translations" => translations}}) do
    {:ok, List.first(translations)["translatedText"]}
  end

  defp translated_text(%{"error" => %{"code" => code, "message" => message}}) do
    {:error, "Error #{code}: #{message}"}
  end
end

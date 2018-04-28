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
      {:ok, %{body: body}} ->
        first = body
          |> Jason.decode!()
          |> (fn(decoded) -> decoded["data"]["translations"] end).()
          |> (fn(translations) -> translations |> List.first() end).()
        {:ok, first["translatedText"]}

      error -> {:error, "Error during request API #{inspect error}"}
    end
  end
end

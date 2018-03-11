defmodule Getatrex.Translator.Google do
  @moduledoc """
  Implementation of gcloudex google translator
  """
  use GCloudex.CloudTranslate.Impl, :cloud_translate

  def translate_to_locale(text, locale) do
    body = %{q: text, target: locale, format: "text"} |> Poison.encode!()

    case Getatrex.Translator.Google.translate(body) do
      {:ok, %{status_code: 200, body: body}} ->
        first_translation = body
          |> Poison.decode!()
          |> (fn(decoded) -> decoded["data"]["translations"] end).()
          |> (fn(translations) -> translations |> List.first() end).()

        {:ok, first_translation["translatedText"]}
      error ->
        {:error, error}
    end
  end

end

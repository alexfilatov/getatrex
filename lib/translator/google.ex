defmodule Getatrex.Translator.Google do
  @moduledoc """
  Implementation of gcloudex google translator
  """
  use GCloudex.CloudTranslate.Impl, :cloud_translate
  alias Getatrex.Translator.Google

  def translate_to_locale("", _), do: {:ok, ""}

  def translate_to_locale(text, locale) do
    body = %{q: text, target: locale, format: "text"} |> Jason.encode!()

    with {:ok, %{status_code: 200, body: body}} <- Google.translate(body) do
      first = body
        |> Jason.decode!()
        |> (fn(decoded) -> decoded["data"]["translations"] end).()
        |> (fn(translations) -> translations |> List.first() end).()
      {:ok, first["translatedText"]}
    else
      error -> {:error, error}
    end
  end

end

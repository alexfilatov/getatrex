defmodule Getatrex.Translator.Google do
  @moduledoc """
  Implementation of gcloudex google translator
  """
  alias Goth.Token
  @endpoint  "https://translation.googleapis.com/language/translate/v2"

  def translate_to_locale("", _, _), do: {:ok, ""}
  def translate_to_locale(text, locale, :post, _) do
    body = %{q: text, target: locale, format: "text"} |> Jason.encode!()
    {:ok, token} = Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    headers = [{"Authorization", "Bearer #{token.token}"}]

    @endpoint
    |> HTTPoison.post(body, headers)
    |> process_request_result()
  end
  def translate_to_locale(text, locale, :get, api_key) do
    query = "?key=#{api_key}&source=#{"en"}&target=#{locale}&q=#{text |> URI.encode}"
    "#{@endpoint}#{query}"
    |> HTTPoison.get()
    |> process_request_result()
  end

  defp process_request_result(http_request_result) do
    case http_request_result do
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

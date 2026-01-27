defmodule Getatrex.Translator.GoogleTest do
  use ExUnit.Case, async: true

  alias Getatrex.Translator.Google

  test "translates a single string" do
    http_client = fn _endpoint, body, _headers, _opts ->
      send(self(), {:body, Jason.decode!(body)})

      {:ok,
       %{
         status_code: 200,
         body: Jason.encode!(%{"data" => %{"translations" => [%{"translatedText" => "Hallo"}]}})
       }}
    end

    assert {:ok, "Hallo"} =
             Google.translate_to_locale("Hello", "de",
               token: "TEST_TOKEN",
               format: "text",
               http_client: http_client
             )

    assert_receive {:body, %{"q" => ["Hello"], "target" => "de", "format" => "text"}}
  end

  test "translates a batch" do
    http_client = fn _endpoint, body, _headers, _opts ->
      send(self(), {:body, Jason.decode!(body)})

      {:ok,
       %{
         status_code: 200,
         body:
           Jason.encode!(%{
             "data" => %{"translations" => [%{"translatedText" => "Uno"}, %{"translatedText" => "Dos"}]}
           })
       }}
    end

    assert {:ok, ["Uno", "Dos"]} =
             Google.translate_to_locale(["One", "Two"], "es",
               token: "TEST_TOKEN",
               format: "text",
               http_client: http_client
             )

    assert_receive {:body, %{"q" => ["One", "Two"], "target" => "es", "format" => "text"}}
  end

  test "returns error from API" do
    http_client = fn _endpoint, _body, _headers, _opts ->
      {:ok,
       %{
         status_code: 400,
         body: Jason.encode!(%{"error" => %{"code" => 400, "message" => "bad"}})
       }}
    end

    assert {:error, "Error 400: bad"} =
             Google.translate_to_locale("Hello", "de",
               token: "TEST_TOKEN",
               format: "text",
               http_client: http_client
             )
  end
end

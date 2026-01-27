defmodule Getatrex.POTest do
  use ExUnit.Case

  alias Getatrex.PO
  import Getatrex.Test.Helper

  defmodule TestTranslator do
    def translate_to_locale(text, _locale, opts) when is_binary(text) do
      send(self(), {:translated, text, opts})
      {:ok, "T:" <> text}
    end

    def translate_to_locale(texts, _locale, opts) when is_list(texts) do
      send(self(), {:translated_batch, texts, opts})
      {:ok, Enum.map(texts, &"T:" <> &1)}
    end
  end

  test "translates singular strings and preserves placeholders" do
    source = write_tmp_file("singular.po", """
    msgid ""
    msgstr ""
    "Language: es\\n"

    #: file.ex:1
    msgid "Hello %{name}"
    msgstr ""
    """)

    target = tmp_file("singular_translated.po")

    {:ok, _stats} = PO.translate_file(source, target, "es", translator: TestTranslator)

    translated = Expo.PO.parse_file!(target)
    msgstr = message_msgstr(translated.messages, "Hello %{name}")

    assert msgstr == "T:Hello %{name}"
  end

  test "translates plural strings" do
    source = write_tmp_file("plural.po", """
    msgid ""
    msgstr ""
    "Language: fr\\n"

    #: file.ex:1
    msgid "Cat"
    msgid_plural "Cats"
    msgstr[0] ""
    msgstr[1] ""
    """)

    target = tmp_file("plural_translated.po")

    {:ok, _stats} = PO.translate_file(source, target, "fr", translator: TestTranslator)

    translated = Expo.PO.parse_file!(target)
    msgstr = message_plural_msgstr(translated.messages, "Cat")

    assert msgstr[0] == ["T:Cat"]
    assert msgstr[1] == ["T:Cats"]
  end

  test "uses html format when tags are present" do
    source = write_tmp_file("html.po", """
    msgid ""
    msgstr ""
    "Language: it\\n"

    #: file.ex:1
    msgid "Click <b>here</b>"
    msgstr ""
    """)

    target = tmp_file("html_translated.po")

    {:ok, _stats} = PO.translate_file(source, target, "it", translator: TestTranslator)

    assert_receive {:translated, _text, opts}
    assert opts[:format] == "html"
  end

  test "keeps existing translations" do
    source = write_tmp_file("existing.po", """
    msgid ""
    msgstr ""
    "Language: es\\n"

    #: file.ex:1
    msgid "Hello"
    msgstr "Hola"
    """)

    target = tmp_file("existing_translated.po")

    {:ok, stats} = PO.translate_file(source, target, "es", translator: TestTranslator)

    translated = Expo.PO.parse_file!(target)
    msgstr = message_msgstr(translated.messages, "Hello")

    assert msgstr == "Hola"
    assert stats.translated == 0
    assert stats.errors == 0
    assert stats.skipped >= 1
  end

  defp message_msgstr(messages, msgid) do
    %Expo.Message.Singular{msgstr: [msgstr]} =
      Enum.find(messages, fn
        %Expo.Message.Singular{msgid: message_msgid} ->
          IO.iodata_to_binary(message_msgid) == msgid

        _ ->
          false
      end)

    msgstr
  end

  defp message_plural_msgstr(messages, msgid) do
    %Expo.Message.Plural{msgstr: msgstr} =
      Enum.find(messages, fn
        %Expo.Message.Plural{msgid: message_msgid} ->
          IO.iodata_to_binary(message_msgid) == msgid

        _ ->
          false
      end)

    msgstr
  end
end

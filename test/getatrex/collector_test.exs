defmodule Getatrex.CollectorTest do
  use ExUnit.Case
  alias Getatrex.{Collector, Writer}
  import Getatrex.Test.Helper
  import Mock

  setup context do
    if context[:writer] do
      reset_file() |> Writer.start_link()
    end
    # Goth.Supervisor.start_link

    {:ok, pid} = Collector.start_link("de")
    %{pid: pid}
  end

  test "dispatching a mention", %{pid: pid} do
    Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:17")
    state = :sys.get_state(pid) # this is we are waiting for async task to complete :)

    assert state == %Getatrex.Message{
      mentions: ["#: web/templates/layout/top_navigation.html.eex:17"],
      msgid: nil,
      msgstr: nil,
      to_lang: "de",
      request_mode: :post,
      api_key: nil
    }

    Collector.dispatch_line("#: web/templates/layout/top_navigation2.html.eex:18")
    state = :sys.get_state(pid)

    assert state == %Getatrex.Message{
      mentions: [
        "#: web/templates/layout/top_navigation.html.eex:17",
        "#: web/templates/layout/top_navigation2.html.eex:18"],
      msgid: nil,
      msgstr: nil,
      to_lang: "de",
      request_mode: :post,
      api_key: nil
    }
  end

  @tag :writer
  test "dispatching a simple line", %{pid: pid} do
    Collector.dispatch_line("# HELLO, THIS IS COMMENT\n")
    :sys.get_state(pid)
    assert file_contents() == "# HELLO, THIS IS COMMENT\n"

    Collector.dispatch_line("# HELLO, THIS IS COMMENT2\n")
    :sys.get_state(pid)
    assert file_contents() == ["# HELLO, THIS IS COMMENT\n", "# HELLO, THIS IS COMMENT2\n"] |> Enum.join("")
  end

  @tag :writer
  test "correct translation", %{pid: pid} do
    # msgid "Here is one string to translate"
    # msgstr "Aqui está um texto para traduzir"
    #
    # msgid "Here is the string to translate"
    # msgid_plural "Here are the strings to translate"
    # msgstr[0] "Aqui está o texto para traduzir"
    # msgstr[1] "Aqui estão os textos para traduzir"

    Collector.dispatch_line(~s(msgid "Here is one string to translate"\n))
    state = :sys.get_state(pid)
    assert state.msgid == "Here is one string to translate"

    # here we translate msgid:
    # 1. assert called translator
    # 2. assert result of translation
    # 2.1 correct translation
    with_mock Getatrex.Translator.Google, [translate_to_locale: fn(_text, _locale, :post, nil) -> {:ok, "TRANSLATED STRING"} end] do
      Collector.dispatch_line(~s(msgstr ""\n))
      state = :sys.get_state(pid)

      assert called Getatrex.Translator.Google.translate_to_locale("Here is one string to translate", "de", :post, nil)
      assert state.msgstr == "TRANSLATED STRING"
    end
  end

  @tag :writer
  test "error during translation", %{pid: pid} do
    Collector.dispatch_line(~s(msgid "Here is one string to translate"\n))
    state = :sys.get_state(pid)
    assert state.msgid == "Here is one string to translate"

    with_mock Getatrex.Translator.Google, [translate_to_locale: fn(_text, _locale, :post, nil) -> {:error, :some_error} end] do
      Collector.dispatch_line(~s(msgstr ""\n))
      state = :sys.get_state(pid)

      assert called Getatrex.Translator.Google.translate_to_locale("Here is one string to translate", "de", :post, nil)
      assert state.msgstr == ""
    end
  end

  describe "writing message" do
    @tag :writer
    test "writing entire simple message", %{pid: pid} do
      with_mock Getatrex.Translator.Google, [translate_to_locale: fn(_text, _locale, :post, nil) -> {:ok, "TRANSLATED STRING"} end] do
        Collector.dispatch_line(~s(msgid "Here is one string to translate"))
        Collector.dispatch_line(~s(msgstr ""))
        Collector.dispatch_line("")

        state = :sys.get_state(pid)
        assert file_contents() == ([
          ~s(msgid "Here is one string to translate"),
          ~s(msgstr "TRANSLATED STRING"),
          ""
          ] |> Enum.join("\n")
          ) <> "\n"
      end
    end

    @tag :writer
    test "writing entire simple message with mentions", %{pid: pid} do
      with_mock Getatrex.Translator.Google, [:passthrough], [translate_to_locale: fn(_text, _locale, :post, nil) -> {:ok, "TRANSLATED STRING"} end] do
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:17")
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:18")
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:19")
        Collector.dispatch_line(~s(msgid "Here is one string to translate"))
        Collector.dispatch_line(~s(msgstr ""))
        Collector.dispatch_line("")

        assert file_contents() == ([
          "#: web/templates/layout/top_navigation.html.eex:17",
          "#: web/templates/layout/top_navigation.html.eex:18",
          "#: web/templates/layout/top_navigation.html.eex:19",
          ~s(msgid "Here is one string to translate"),
          ~s(msgstr "TRANSLATED STRING"),
          ""
          ] |> Enum.join("\n")
          ) <> "\n"
      end
    end

    @tag :writer
    test "writing two blocks", %{pid: pid} do
      with_mock Getatrex.Translator.Google, [:passthrough], [translate_to_locale: fn(_text, _locale, :post, nil) -> {:ok, "TRANSLATED STRING"} end] do
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:17")
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:18")
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:19")
        Collector.dispatch_line(~s(msgid "Here is one string to translate"))
        Collector.dispatch_line(~s(msgstr ""))
        Collector.dispatch_line("")

        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:21")
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:22")
        Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:23")
        Collector.dispatch_line(~s(msgid "Here is one string to translate2"))
        Collector.dispatch_line(~s(msgstr ""))
        Collector.dispatch_line("")

        assert file_contents() == ([
          "#: web/templates/layout/top_navigation.html.eex:17",
          "#: web/templates/layout/top_navigation.html.eex:18",
          "#: web/templates/layout/top_navigation.html.eex:19",
          ~s(msgid "Here is one string to translate"),
          ~s(msgstr "TRANSLATED STRING"),
          "",
          "#: web/templates/layout/top_navigation.html.eex:21",
          "#: web/templates/layout/top_navigation.html.eex:22",
          "#: web/templates/layout/top_navigation.html.eex:23",
          ~s(msgid "Here is one string to translate2"),
          ~s(msgstr "TRANSLATED STRING"),
          "",
          ] |> Enum.join("\n")
          ) <> "\n"
      end
    end

    @tag :writer
    test "language block", %{pid: pid} do
      with_mock Getatrex.Translator.Google, [:passthrough], [translate_to_locale: fn(_text, _locale, :post, nil) -> {:ok, "TRANSLATED STRING"} end] do
        Collector.dispatch_line("## Use `mix gettext.extract --merge` or `mix gettext.merge`")
        Collector.dispatch_line("## to merge POT files into PO files.")
        Collector.dispatch_line(~s(msgid ""))
        Collector.dispatch_line(~s(msgstr ""))
        Collector.dispatch_line(~s("Language: de\n"))

        assert file_contents() == ([
          ~s(## Use `mix gettext.extract --merge` or `mix gettext.merge`),
          ~s(## to merge POT files into PO files.),
          ~s(msgid ""),
          ~s(msgstr ""),
          ~s("Language: de\n"),
          "",
          ] |> Enum.join("\n")
          )
      end
    end

    @tag :writer
    test "already translated block", %{pid: pid} do
      Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:19")
      Collector.dispatch_line(~s(msgid "Here is one string to translate"))
      Collector.dispatch_line(~s(msgstr "Translated line"))
      Collector.dispatch_line("")

      assert file_contents() == ([
          ~s(#: web/templates/layout/top_navigation.html.eex:19),
          ~s(msgid "Here is one string to translate"),
          ~s(msgstr "Translated line"),
          "",
        ] |> Enum.join("\n")
      ) <> "\n"
    end
  end

end

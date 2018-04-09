defmodule Getatrex.CollectorTest do
  use ExUnit.Case
  alias Getatrex.{Collector, Writer}
  import Getatrex.Test.Helper
  import Mock

  setup context do
    if context[:writer] do
      reset_file() |> Writer.start_link()
    end

    {:ok, pid} = Collector.start_link()
    %{pid: pid}
  end

  test "dispatching a mention", %{pid: pid} do
    Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:17")
    state = :sys.get_state(pid) # this is we are waiting for async task to complete :)

    assert state == %Getatrex.Message{
      mentions: ["#: web/templates/layout/top_navigation.html.eex:17"],
      msgid: "",
      msgstr: ""
    }

    Collector.dispatch_line("#: web/templates/layout/top_navigation2.html.eex:18")
    state = :sys.get_state(pid)

    assert state == %Getatrex.Message{
      mentions: [
        "#: web/templates/layout/top_navigation.html.eex:17",
        "#: web/templates/layout/top_navigation2.html.eex:18"],
      msgid: "",
      msgstr: ""
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
    with_mock Getatrex.Translator.Google, [translate_to_locale: fn(_text, _locale) -> {:ok, "TRANSLATED STRING"} end] do
      Collector.dispatch_line(~s(msgstr ""\n))
      state = :sys.get_state(pid)

      assert called Getatrex.Translator.Google.translate_to_locale("Here is one string to translate", "de")
      assert state.msgstr == "TRANSLATED STRING"
    end
  end

  @tag :writer
  test "error during translation", %{pid: pid} do
    Collector.dispatch_line(~s(msgid "Here is one string to translate"\n))
    state = :sys.get_state(pid)
    assert state.msgid == "Here is one string to translate"

    with_mock Getatrex.Translator.Google, [translate_to_locale: fn(_text, _locale) -> {:error, :some_error} end] do
      Collector.dispatch_line(~s(msgstr ""\n))
      state = :sys.get_state(pid)

      assert called Getatrex.Translator.Google.translate_to_locale("Here is one string to translate", "de")
      assert state.msgstr == ""
    end
  end

end

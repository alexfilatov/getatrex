defmodule Getatrex.WriterTest do
  use ExUnit.Case
  alias Getatrex.Writer
  import Getatrex.Test.Helper

  setup do
    {:ok, pid} = reset_file() |> Writer.start_link()

    %{pid: pid}
  end

  describe "writing single lines" do
    test "writing single line" do
      line = "hello world\n"

      Writer.write(line)

      assert file_contents() == line
    end
  end

  describe "writing Message structs" do
    test "with one mention" do
      message = %Getatrex.Message{
        mentions: ["#: web/templates/layout/top_navigation.html.eex:17"],
        msgid: "Home",
        msgstr: "Haus",
        to_lang: "de"
      }

      Writer.write(message)

      assert file_contents() == ([
        "#: web/templates/layout/top_navigation.html.eex:17",
        ~s(msgid "Home"),
        ~s(msgstr "Haus")
      ] |> Enum.join("\n")
      ) <> "\n\n"
    end

    test "with multiple mentions" do
      message = %Getatrex.Message{
        mentions: [
          "#: web/templates/layout/top_navigation.html.eex:17",
          "#: web/templates/layout/top_navigation.html.eex:18",
          "#: web/templates/layout/top_navigation.html.eex:19"
        ],
        msgid: "Home",
        msgstr: "Haus",
        to_lang: "de"
      }

      Writer.write(message)

      assert file_contents() == ([
        [
          "#: web/templates/layout/top_navigation.html.eex:17",
          "#: web/templates/layout/top_navigation.html.eex:18",
          "#: web/templates/layout/top_navigation.html.eex:19"
        ] |> Enum.join("\n"),
        ~s(msgid "Home"),
        ~s(msgstr "Haus")
        ] |> Enum.join("\n")
        ) <> "\n\n"
    end
  end

end

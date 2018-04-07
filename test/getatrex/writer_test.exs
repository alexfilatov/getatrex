defmodule Getatrex.WriterTest do
  use ExUnit.Case
  alias Getatrex.Writer
  import Getatrex.Test.Helper

  setup do
    filename = "filename.txt"
    {:ok, pid} = reset_file() |> Writer.start_link()

    %{pid: pid, filename: filename}
  end

  describe "writing single lines" do
    test "writing single line", %{filename: _filename} do
      line = "hello world\n"

      Writer.write(line)

      assert file_contents() == line
    end
  end

  describe "writing Message structs" do
    test "with one mention", %{filename: _filename} do
      message = %Getatrex.Message{
        mentions: ["#: web/templates/layout/top_navigation.html.eex:17"],
        msgid: "Home",
        msgstr: "Haus"
      }

      Writer.write(message)

      assert file_contents() == ["", "#: web/templates/layout/top_navigation.html.eex:17", ~s(msgid "Home"), ~s(msgstr "Haus")] |> Enum.join("\n")
    end

    test "with multiple mentions", %{filename: _filename} do
      message = %Getatrex.Message{
        mentions: ["#: web/templates/layout/top_navigation.html.eex:17", "#: web/templates/layout/top_navigation.html.eex:18", "#: web/templates/layout/top_navigation.html.eex:19"],
        msgid: "Home",
        msgstr: "Haus"
      }

      Writer.write(message)

      assert file_contents() == [
        "",
        ["#: web/templates/layout/top_navigation.html.eex:17", "#: web/templates/layout/top_navigation.html.eex:18", "#: web/templates/layout/top_navigation.html.eex:19"] |> Enum.join("\n"),
        ~s(msgid "Home"),
        ~s(msgstr "Haus")
        ] |> Enum.join("\n")
    end
  end

end

defmodule Getatrex.CollectorTest do
  use ExUnit.Case
  alias Getatrex.{Collector, Writer}
  import Getatrex.Test.Helper

  setup context do
    if context[:writer] do
      reset_file() |> Writer.start_link()
    end

    {:ok, pid} = Collector.start_link()
    %{pid: pid}
  end

  test "dispatching a mention", %{pid: pid} do
    Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:17")
    state = :sys.get_state(pid)

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
    _state = :sys.get_state(pid)
    assert file_contents() == "# HELLO, THIS IS COMMENT\n"

    Collector.dispatch_line("# HELLO, THIS IS COMMENT2\n")
    _state = :sys.get_state(pid)
    assert file_contents() == ["# HELLO, THIS IS COMMENT\n", "# HELLO, THIS IS COMMENT2\n"] |> Enum.join("")
  end

end

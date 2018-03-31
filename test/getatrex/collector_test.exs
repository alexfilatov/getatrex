defmodule Getatrex.CollectorTest do
  use ExUnit.Case
  alias Getatrex.Collector
  import Getatrex.Test.Helper

  setup do
    {:ok, pid} = Getatrex.Collector.start_link()

    %{pid: pid}
  end

  test "testing dispatching a mention", %{pid: pid} do
    Getatrex.Collector.dispatch_line("#: web/templates/layout/top_navigation.html.eex:17")
    state = :sys.get_state(pid)

    assert state == %Getatrex.Message{
      mentions: ["#: web/templates/layout/top_navigation.html.eex:17"],
      msgid: "",
      msgstr: ""
    }

    Getatrex.Collector.dispatch_line("#: web/templates/layout/top_navigation2.html.eex:18")
    state = :sys.get_state(pid)

    assert state == %Getatrex.Message{
      mentions: [
        "#: web/templates/layout/top_navigation.html.eex:17",
        "#: web/templates/layout/top_navigation2.html.eex:18"],
      msgid: "",
      msgstr: ""
    }
  end

end

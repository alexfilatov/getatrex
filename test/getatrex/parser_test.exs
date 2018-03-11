defmodule Getatrex.ParserTest do
  use ExUnit.Case
  doctest Getatrex.Parser
  alias Getatrex.Parser

  test "parse msgid string" do
    assert {:ok, "Welcome!"} == Parser.msgid_message("msgid \"Welcome!\"")
    assert {:error, :msgid_not_found} == Parser.msgid_message("msgid wrong string")
    assert {:error, :msgid_not_found} == Parser.msgid_message("msgid")
    assert {:error, :msgid_not_found} == Parser.msgid_message("some test string")
  end

end

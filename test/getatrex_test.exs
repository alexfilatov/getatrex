defmodule GetatrexTest do
  use ExUnit.Case
  doctest Getatrex

  test "parse msgid string" do
    assert {:ok, "Welcome!"} == Getatrex.Parser.msgid_message("msgid \"Welcome!\"")
    assert {:error, :msgid_not_found} == Getatrex.Parser.msgid_message("msgid wrong string")
    assert {:error, :msgid_not_found} == Getatrex.Parser.msgid_message("msgid")
    assert {:error, :msgid_not_found} == Getatrex.Parser.msgid_message("some test string")
  end
end

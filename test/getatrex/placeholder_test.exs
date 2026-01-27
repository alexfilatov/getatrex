defmodule Getatrex.PlaceholderTest do
  use ExUnit.Case

  test "protects and restores placeholders" do
    original = "Hello %{name}, welcome to {{site}}"

    prepared = Getatrex.Placeholder.prepare(original)
    refute prepared == original

    restored = Getatrex.Placeholder.restore(prepared)
    assert restored == original
  end

  test "restores string without placeholders" do
    original = "No placeholders here"

    prepared = Getatrex.Placeholder.prepare(original)
    restored = Getatrex.Placeholder.restore(prepared)

    assert restored == original
  end
end

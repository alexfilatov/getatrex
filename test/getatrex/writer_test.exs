defmodule Getatrex.WriterTest do
  use ExUnit.Case
  alias Getatrex.Writer
  import Getatrex.Test.Helper

  setup do
    filename = "filename.txt"
    {:ok, pid} = filename
    |> reset_file()
    |> Getatrex.Writer.start_link()

    %{pid: pid, filename: filename}
  end

  test "writing single line", %{filename: filename} do
    line = "hello world"

    line |> Getatrex.Writer.write()

    content = filename
    |> get_support_path()
    |> File.read!()

    assert content == line
  end

end

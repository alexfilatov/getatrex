ExUnit.start()

defmodule Getatrex.Test.Helper do

  def get_support_path(filename) do
    "./test/support/#{filename}"
  end

  def reset_file(filename) do
    filename |> get_support_path() |> File.write!("")
    get_support_path(filename)
  end

end

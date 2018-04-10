ExUnit.start()

defmodule Getatrex.Test.Helper do
  def filename do
    "filename.txt"
  end

  def get_support_path do
    "./test/support/#{filename()}"
  end

  def reset_file do
    get_support_path() |> File.write!("")
    get_support_path()
  end

  def file_contents do
    get_support_path() |> File.read!()
  end
end

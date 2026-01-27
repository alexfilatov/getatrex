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

  def tmp_dir do
    System.tmp_dir!()
    |> Path.join("getatrex_test")
    |> tap(&File.mkdir_p!/1)
  end

  def tmp_file(filename) do
    Path.join(tmp_dir(), filename)
  end

  def write_tmp_file(filename, contents) do
    path = tmp_file(filename)
    File.write!(path, contents)
    path
  end
end

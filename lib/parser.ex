defmodule Getatrex.Parser do
  @moduledoc """
  Parser for lines in the .po file:
  - msgid strings
  """

  @doc """
  Parses msgid line of the .PO file

  ## Example

      iex> Getatrex.Parser.msgid_message(~s(msgid "Welcome"))
      {:ok, "Welcome"}

      iex> Getatrex.Parser.msgid_message("msgid test")
      {:error, :msgid_not_found}

      iex> Getatrex.Parser.msgid_message("simple string")
      {:error, :msgid_not_found}

  """
  def msgid_message(line) do
    case Regex.scan(~r/msgid\s+"(.*)"\s*/, line) do
      [] -> {:error, :msgid_not_found}
      [match] -> {:ok, Enum.at(match, 1)}
      _ -> {:error, :msgid_parser_unexpected_error}
    end
  end

end

defmodule Getatrex.Parser do
  
    def msgid_message(line) do
        case Regex.scan(~r/msgid\s+"(.*)"\s*/, line) do
            [] -> {:error, :msgid_not_found}
            [match] -> {:ok, Enum.at(match, 1)}
            _ -> {:error, :msgid_parser_unexpected_error}
        end
    end

end

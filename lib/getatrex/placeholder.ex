defmodule Getatrex.Placeholder do
  @moduledoc false

  @variable_regex ~r/%{([^}]+)}/
  @mustache_regex ~r/\{\{([^}]+)\}\}/

  def prepare(text) when is_binary(text) do
    text
    |> protect(@variable_regex, "GETATREX_VAR")
    |> protect(@mustache_regex, "GETATREX_MUSTACHE")
  end

  def restore(text) when is_binary(text) do
    text
    |> restore(variable_regex_token(), &"%{#{decode(&1)}}")
    |> restore(mustache_regex_token(), &"{{#{decode(&1)}}}")
  end

  defp protect(text, regex, token_prefix) do
    Regex.replace(regex, text, fn _, value ->
      "#{token_prefix}[#{Base.encode64(value, padding: false)}]"
    end)
  end

  defp restore(text, regex, builder) do
    Regex.replace(regex, text, fn _, encoded -> builder.(encoded) end)
  end

  defp decode(value), do: Base.decode64!(value, padding: false)

  defp variable_regex_token, do: ~r/GETATREX_VAR\[([^\]]+)\]/
  defp mustache_regex_token, do: ~r/GETATREX_MUSTACHE\[([^\]]+)\]/
end

defmodule Mix.Tasks.GetatrexTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Getatrex

  defmodule TestTranslator do
    def translate_to_locale(text, _locale, _opts), do: {:ok, "T:" <> text}
  end

  setup do
    locale = "en"
    base = Path.join([File.cwd!(), "priv", "gettext", locale, "LC_MESSAGES"])
    File.mkdir_p!(base)

    Application.put_env(:getatrex, :translator, TestTranslator)

    Process.put(:backup_files, %{})

    on_exit(fn ->
      Application.delete_env(:getatrex, :translator)
      restore_backups()
    end)

    {:ok, locale: locale, base: base}
  end

  test "prints warning when locale file missing", %{locale: locale, base: base} do
    remove_po_file(Path.join(base, "errors.po"))

    output = capture_io(fn -> Getatrex.run([locale, "--domain", "errors"]) end)

    assert output =~ "Warning!"
    assert output =~ "does not exists"
  end

  test "translates default domain", %{locale: locale, base: base} do
    write_po_file(Path.join(base, "default.po"), po_fixture())
    remove_po_file(Path.join(base, "translated_default.po"))

    capture_io(fn -> Getatrex.run([locale]) end)

    translated = File.read!(Path.join(base, "translated_default.po"))
    assert translated =~ "msgstr \"T:Hello\""
  end

  test "translates errors domain", %{locale: locale, base: base} do
    write_po_file(Path.join(base, "errors.po"), po_fixture())
    remove_po_file(Path.join(base, "translated_errors.po"))

    capture_io(fn -> Getatrex.run([locale, "--domain", "errors"]) end)

    translated = File.read!(Path.join(base, "translated_errors.po"))
    assert translated =~ "msgstr \"T:Hello\""
  end

  test "translates multiple domains", %{locale: locale, base: base} do
    write_po_file(Path.join(base, "default.po"), po_fixture("Hello"))
    write_po_file(Path.join(base, "errors.po"), po_fixture("Oops"))
    remove_po_file(Path.join(base, "translated_default.po"))
    remove_po_file(Path.join(base, "translated_errors.po"))

    capture_io(fn -> Getatrex.run([locale, "--domain", "default", "--domain", "errors"]) end)

    translated_default = File.read!(Path.join(base, "translated_default.po"))
    translated_errors = File.read!(Path.join(base, "translated_errors.po"))

    assert translated_default =~ "msgstr \"T:Hello\""
    assert translated_errors =~ "msgstr \"T:Oops\""
  end

  defp po_fixture(message \\ "Hello") do
    ~s(msgid ""\nmsgstr ""\n"Language: en\\n"\n\nmsgid "#{message}"\nmsgstr ""\n)
  end

  defp write_po_file(path, contents) do
    backups = Process.get(:backup_files, %{})

    backups =
      if Map.has_key?(backups, path) do
        backups
      else
        backup =
          case File.read(path) do
            {:ok, data} -> {:exists, data}
            {:error, _} -> :missing
          end

        Map.put(backups, path, backup)
      end

    Process.put(:backup_files, backups)
    File.write!(path, contents)
  end

  defp remove_po_file(path) do
    backups = Process.get(:backup_files, %{})

    backups =
      if Map.has_key?(backups, path) do
        backups
      else
        backup =
          case File.read(path) do
            {:ok, data} -> {:exists, data}
            {:error, _} -> :missing
          end

        Map.put(backups, path, backup)
      end

    Process.put(:backup_files, backups)
    File.rm(path)
  end

  defp restore_backups do
    backups = Process.get(:backup_files, %{})

    Enum.each(backups, fn {path, backup} ->
      case backup do
        {:exists, data} -> File.write!(path, data)
        :missing -> File.rm(path)
      end
    end)

    Process.delete(:backup_files)
  end
end

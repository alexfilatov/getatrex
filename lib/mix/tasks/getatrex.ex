defmodule Mix.Tasks.Getatrex do
  @moduledoc """
  Runs locale translation routine
  """
  use Mix.Task
  use GenServer
  use Gettext, otp_app: :getatrex

  @shortdoc "Translates gettext locale with Google Cloud Translate API"

  @doc """
  Runs the routine

  1. Check whether target locale exists, files errors.po, default.po
  2. Start reading `default.po` in the stream
  3. Collect translation groups by comments(location in templates) + msgid line(original) + msgstr line(translated)
  4. When translation group is collected - translate and save to msgstr line
  5. When translation is done - write group to disk
  6. When translation failed - write not translated group to disk (to re-run this later)
  7. All read/write are sync (to respect the order)
  8.
  """
  def run(argv) do
    {switches, args, _invalid} = 
      argv
      |> OptionParser.parse(aliases: [a: :all], strict: [all: :boolean, no_error_po: :boolean, replace: :boolean, request_mode: :string, api_key: :string])

      switches
      |> which_languages(args)
      |> Enum.map(fn to_lang -> translate_po(to_lang, error_po?(switches), replace?(switches), request_mode(switches), api_key(switches)) end)
  end

  def translate_po(to_lang, error_po?, replace?, :get, api_key) when is_nil(api_key) do
    Mix.shell.info "Error!"
    Mix.shell.info "API key missing"
    Mix.shell.info ""
  end

  def translate_po(to_lang, error_po?, replace?, :post, api_key)  when is_nil(api_key) == false do
    Mix.shell.info "Error!"
    Mix.shell.info "POST doesn't use API key"
    Mix.shell.info ""
  end

  def translate_po(to_lang, error_po?, replace?, request_mode, api_key) do
    # checking whether local exists and run if file exists

    # default.po
    to_lang
    |> locale_path_po(:default)
    |> File.exists?()
    |> run_with_file(to_lang, :default, replace?, request_mode, api_key)

    # errors.po
    if error_po? do
      to_lang
      |> locale_path_po(:errors)
      |> File.exists?()
      |> run_with_file(to_lang, :errors, replace?, request_mode, api_key)
    end 
  end

  def run_with_file(true, to_lang, messages_file, replace?, request_mode, api_key) do
    Mix.shell.info "Starting translation #{messages_file} gettext locale #{to_lang}"

    {:ok, pid_writer} =
      to_lang
      |> translated_locale_path_po(messages_file)
      |> Getatrex.Writer.start_link()

    {:ok, pid_wcollector} = 
      Getatrex.Collector.start_link(to_lang, request_mode, api_key)

    to_lang
    |> locale_path_po(messages_file)
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.with_index()
    |> Stream.map(fn {line, i} ->
          IO.puts "#{i}: #{line}"
          Getatrex.Collector.dispatch_line(line)
        end)
    |> Stream.run()

    Getatrex.Collector.dispatch_line("")
    Mix.shell.info "Done!"

    GenServer.stop(pid_writer)
    GenServer.stop(pid_wcollector)

    if replace?, do: rename_files(to_lang, messages_file)
  end

  def run_with_file(false, to_lang, messages_file, _request_mode) do
    Mix.shell.info "Warning!"
    Mix.shell.info "Locale filename #{locale_path_po(to_lang, messages_file)} does not exists."
    Mix.shell.info "Please create '#{to_lang}' locale with gettext first:"
    Mix.shell.info "Follow the instructions:"
    Mix.shell.info ""
    Mix.shell.info "$ mix gettext.extract"
    Mix.shell.info "$ mix gettext.merge priv/gettext"
    Mix.shell.info "$ mix gettext.merge priv/gettext --locale #{to_lang}"
    Mix.shell.info ""
    Mix.shell.info "More info here: https://github.com/elixir-lang/gettext#workflow"
  end

 def run(_), do: run()

 def run do
    Mix.shell.info "Call this task in the following way:"
    Mix.shell.info ""
    Mix.shell.info "\t$ mix getatrex es"
    Mix.shell.info ""
    Mix.shell.info "where `es` - target language (should be created by gettext before getatrex)"
    Mix.shell.info ""
    Mix.shell.info "Options:"
    Mix.shell.info "\t-a, --a\t - target all available languages"
    Mix.shell.info "\t--no-error-po\t - doesn't translate `error_po` files (default translate)"
    Mix.shell.info "\t--replace\t - replace and backup previous translations (default doesn't replace)"
    Mix.shell.info "\t--request_mode [:post | :get --api_key <key>]\t - method to query google apis. GET method require to supply a valid api key to the --api-key switch"
    Mix.shell.info "Please read README.md https://github.com/alexfilatov/getatrex#getting-started"
 end

 def rename_files(to_lang, messages_file) do

   translated_locale_path_po(to_lang, messages_file)
   locale_path_po(to_lang, messages_file)
   backup_locale_path_po(to_lang, messages_file)

   Mix.shell.info "---> Backing up: #{locale_path_po(to_lang, messages_file)}"
   with :ok <- File.rename(locale_path_po(to_lang, messages_file), backup_locale_path_po(to_lang, messages_file)),
        :ok <- File.rename(translated_locale_path_po(to_lang, messages_file), locale_path_po(to_lang, messages_file)) do
        :ok
   else
      {:error, error} -> Mix.shell.info "An error occoured renaming files: #{inspect error}"
   end
 end

  @doc """
  Returns path to the locale generated by gettext
  """
  defp locale_path_po(to_lang, messages_file) do
    case messages_file do
      :default -> "./priv/gettext/#{to_lang}/LC_MESSAGES/default.po"
      :errors -> "./priv/gettext/#{to_lang}/LC_MESSAGES/errors.po"
    end
  end

  @doc """
  Returns path for translated locale
  """
  defp translated_locale_path_po(to_lang, messages_file) do
    case messages_file do
      :default -> "./priv/gettext/#{to_lang}/LC_MESSAGES/translated_default.po"
      :errors -> "./priv/gettext/#{to_lang}/LC_MESSAGES/translated_errors.po"
    end
  end

  @doc """
  Returns path for source backup
  """
  defp backup_locale_path_po(to_lang, messages_file) do
    case messages_file do
      :default -> "./priv/gettext/#{to_lang}/LC_MESSAGES/default.po.BAK"
      :errors -> "./priv/gettext/#{to_lang}/LC_MESSAGES/errors.po.BAK"
    end
  end

  defp which_languages(switches, argv) do
      case Keyword.get(switches, :all, false) do
        true -> known_locales()
        false -> argv
      end
  end

  @doc """
  Returns path for locales, dropping "en" from the list
  """
  defp known_locales() do
    dir = "./priv/gettext/"
    dir
    |> File.ls!() 
    |> Enum.filter(&File.dir?(Path.join(dir, &1)))
    |> Enum.filter(fn locale -> locale != "en" end)
  end

  defp replace?(switches) do
    switches
    |> Keyword.get(:replace, false)
  end

  defp request_mode(switches) do
    switches
    |> Keyword.get(:request_mode, "post")
    |> String.downcase()
    |> String.to_atom()
  end

  defp error_po?(switches) do
    ! Keyword.get(switches, :no_error_po, false)
  end

  defp api_key(switches) do
    switches
    |> Keyword.get(:api_key, nil)
  end
end

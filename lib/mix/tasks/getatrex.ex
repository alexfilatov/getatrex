defmodule Mix.Tasks.Getatrex do
  @moduledoc """
  Runs locale translation routine
  """

  use Mix.Task

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
  def run([from_lang, to_lang | tail]) do
    Mix.shell.info "Starting..."

    


    Mix.shell.info "Done!"
  end

  def run(_), do: run()
  def run do
    Mix.shell.info "Call this task in the following way:"
    Mix.shell.info ""
    Mix.shell.info "\t$ mix getatrex es"
    Mix.shell.info ""
    Mix.shell.info "where `es` - target language, to translate to"
    Mix.shell.info ""
    Mix.shell.info "Please read README.md https://github.com/alexfilatov/getatrex#getting-started"
  end
end

defmodule Mix.Tasks.Getatrex do

  use Mix.Task

  @shortdoc "Translates gettext locale with Google Cloud Translate API"

  def run([from_lang, to_lang | tail]) do
    Mix.shell.info "Starting..."

    

    Mix.shell.info "Done!"
  end

  def run(_), do: run()
  def run() do
    Mix.shell.info "Call this task in the following way:"
    Mix.shell.info ""
    Mix.shell.info "\t$ mix getatrex es"
    Mix.shell.info ""
    Mix.shell.info "where `es` - target language, to translate to"
    Mix.shell.info ""
    Mix.shell.info "Please read README.md https://github.com/alexfilatov/getatrex#getting-started"
  end
end

defmodule Mix.Tasks.Getatrex do
    use Mix.Task
  
    @shortdoc "Translates gettext locale with Google Translate API"
    def run(args) do
      IO.puts "STARTING..."
      IO.puts "args: #{IO.inspect args}"
      IO.puts "Done!"
    end
end
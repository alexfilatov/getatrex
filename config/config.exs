# This file is responsible for configuring your application
# and its dependencies.
import Config

# Google credentials
config :goth, json: "goth_credentials.json" |> File.read!

config :getatrex, google_translate: [
  format: :auto
]

import_config "#{Mix.env}.exs"

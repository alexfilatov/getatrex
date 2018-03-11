use Mix.Config

# Recommended way to put Google Apps Credentials:
# config :goth, json: {:system, "GOOGLE_APPLICATION_CREDENTIALS"}
# 
config :goth, json: "config/creds_dev.json" |> Path.expand() |> File.read!()

config :remix,
  escript: false,
  silent: false

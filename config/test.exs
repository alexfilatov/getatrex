use Mix.Config

config :goth, json: "config/creds_test.json" |> Path.expand() |> File.read!()
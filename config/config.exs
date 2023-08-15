import Config

config :live_cache, ttl: :timer.seconds(5), sweep_every: :timer.seconds(1)

config :logger, level: :info

import_config("#{Mix.env()}.exs")

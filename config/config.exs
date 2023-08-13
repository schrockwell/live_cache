import Config

config :live_cache, expire_after: :timer.seconds(5)

config :logger, level: :info

import_config("#{Mix.env()}.exs")

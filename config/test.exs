import Config

# Make the expiration faster for testing
config :live_cache, ttl: 500, sweep_every: 100

config :phoenix, :json_library, Jason

# The bare minimum endpoint config to stand up LiveView tests
config :live_cache, LiveCacheTestWeb.Endpoint,
  live_view: [signing_salt: "Fwg_AlGquBjb5QDG"],
  secret_key_base: "3tSiJcsTfkpwpJuaP2t+56N576PbdjhqvcCueAfbMSbr/TbRKxT1YjhGFZAWK848"

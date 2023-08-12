defmodule LiveCache.PerSession do
  @moduledoc """
  Plug to scope cache operations to the current session.

  Installing the plug into a pipeline ensures that cached values are only accessible within this session, as an extra
  layer of security.

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router

        pipeline :browser do
          # [...]
          plug LiveCache.PerSession
        end

  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(_), do: []

  @impl true
  def call(conn, _) do
    if get_session(conn, "live_cache_session") do
      conn
    else
      put_session(conn, "live_cache_session", LiveCache.Cache.generate_cache_key())
    end
  end
end

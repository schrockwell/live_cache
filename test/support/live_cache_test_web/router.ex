defmodule LiveCacheTestWeb.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, {LiveCacheTestWeb.LayoutView, :root})
  end

  pipeline :per_session do
    plug(LiveCache.PerSession)
  end

  scope "/" do
    pipe_through(:browser)
    live("/random", LiveCacheTestWeb.RandomLive)
  end

  scope "/my" do
    pipe_through([:browser, :per_session])
    live("/random", LiveCacheTestWeb.RandomLive)
  end
end

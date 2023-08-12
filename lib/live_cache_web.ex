defmodule LiveCacheWeb do
  import Phoenix.Component

  def live_cache_meta(assigns) do
    ~H"""
    <meta name="live_cache_key" content={@live_cache_key} />
    """
  end
end

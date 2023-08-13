defmodule LiveCacheTestWeb.LayoutView do
  use LiveCacheTestWeb, :view

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <%= csrf_meta_tag() %>
        <%= if assigns[:live_cache_key] do %>
          <meta name="live-cache-key" content={@live_cache_key} />
        <% end %>
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end

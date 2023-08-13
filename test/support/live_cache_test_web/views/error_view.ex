defmodule LiveCacheTestWeb.ErrorView do
  use LiveCacheTestWeb, :view

  def render("500.html", _assigns), do: "oh no"
end

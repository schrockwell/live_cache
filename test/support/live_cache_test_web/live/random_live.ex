defmodule LiveCacheTestWeb.RandomLive do
  use LiveCacheTestWeb, :live_view

  def mount(%{"scope" => scope}, _, socket) do
    socket = assign_cached(socket, :random, [scope: scope], fn -> :rand.uniform() end)
    {:ok, socket}
  end

  def mount(%{"new" => "true"}, _, socket) do
    socket = assign_cached_new(socket, :random, fn -> :rand.uniform() end)
    {:ok, socket}
  end

  def mount(_, _, socket) do
    socket = assign_cached(socket, :random, fn -> :rand.uniform() end)
    {:ok, socket}
  end

  def render(assigns), do: ~H"<div data-test-random><%= @random %></div>"
end

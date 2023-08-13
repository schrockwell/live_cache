defmodule LiveCache.LiveView do
  @moduledoc """
  Integration hook for LiveViews.
  """

  @doc """
  LiveView `on_mount` callback to integrate with LiveCache.

  This function should not called directly. It is a callback invoked via `Phoenix.LiveView.on_mount/1`
  """
  @spec on_mount(:default, map, map, LiveView.Socket.t()) :: {:cont, LiveView.Socket.t()}
  def on_mount(:default, params, session, socket) do
    LiveCache.__on_mount__(:default, params, session, socket)
  end
end

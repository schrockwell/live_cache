defmodule LiveCache.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveCache.Cache.ExpirationServer
    ]

    LiveCache.Cache.new()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveCache.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

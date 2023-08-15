defmodule LiveCache.Cache.ExpirationServer do
  @moduledoc false

  use GenServer

  @table LiveCache.Cache
  @sweep_every Application.compile_env(:live_cache, :sweep_every, :timer.seconds(1))

  def expiration_tick(ttl) do
    ceil((System.monotonic_time(:millisecond) + ttl) / @sweep_every)
  end

  defp current_tick do
    ceil(System.monotonic_time(:millisecond) / @sweep_every)
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_) do
    Process.send_after(self(), :purge, @sweep_every)

    {:ok, []}
  end

  @impl GenServer
  def handle_info(:purge, state) do
    Process.send_after(self(), :purge, @sweep_every)

    # :ets.fun2ms(fn {_cache_key, _scope_key, _value, expiration_tick} -> expiration_tick <= 123 end)
    match_spec = [{{:"$1", :"$2", :"$3", :"$4"}, [], [{:"=<", :"$4", current_tick()}]}]
    :ets.select_delete(@table, match_spec)

    {:noreply, state}
  end
end

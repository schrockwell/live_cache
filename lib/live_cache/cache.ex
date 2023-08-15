defmodule LiveCache.Cache do
  @moduledoc false

  alias LiveCache.Cache.ExpirationServer

  @table LiveCache.Cache

  def new do
    :ets.new(@table, [:bag, :public, :named_table])
  end

  def generate_cache_key do
    Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
  end

  def get_cached_assigns(cache_key) do
    @table
    |> :ets.lookup(cache_key)
    |> Map.new(fn {_cache_key, scope_key, value, _exp} -> {scope_key, value} end)
  end

  def invalidate_all(cache_key) do
    :ets.delete(@table, cache_key)
  end

  def insert(cache_key, scope_key, value, ttl) do
    :ets.insert(@table, {cache_key, scope_key, value, ExpirationServer.expiration_tick(ttl)})
  end

  # Only use this for test setup
  def __reset__ do
    :ets.delete_all_objects(@table)
  end
end

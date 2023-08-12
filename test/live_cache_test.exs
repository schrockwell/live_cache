defmodule LiveCacheTest do
  use ExUnit.Case
  doctest LiveCache

  test "greets the world" do
    assert LiveCache.hello() == :world
  end
end

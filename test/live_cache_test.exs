defmodule LiveCacheTest do
  use ExUnit.Case

  @endpoint LiveCacheTestWeb.Endpoint

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  setup do
    LiveCache.Cache.__invalidate_all__()
    start_supervised!(@endpoint)
    :ok
  end

  describe "assign_cached/4" do
    test "persists a value in the cache" do
      # GIVEN
      dead_doc = get_dead_doc("/random")

      # WHEN
      live_doc = get_live_doc("/random", dead_doc)

      # THEN
      assert get_random(dead_doc) == get_random(live_doc)
    end

    test "invalidates a value after being fetched from the cache" do
      # GIVEN
      dead_doc = get_dead_doc("/random")

      # WHEN
      _live_doc = get_live_doc("/random", dead_doc)
      live_doc = get_live_doc("/random", dead_doc)

      # THEN
      refute get_random(dead_doc) == get_random(live_doc)
    end

    test "invalidates a value after a timeout" do
      # GIVEN
      dead_doc = get_dead_doc("/random")

      # WHEN
      # config/test.exs sets 500ms timeout
      Process.sleep(600)

      # THEN
      live_doc = get_live_doc("/random", dead_doc)

      refute get_random(dead_doc) == get_random(live_doc)
    end

    test "can retrieve cached values from the same scope" do
      # GIVEN
      dead_doc = get_dead_doc("/random?scope=one")

      # WHEN
      live_doc = get_live_doc("/random?scope=one", dead_doc)

      # THEN
      assert get_random(dead_doc) == get_random(live_doc)
    end

    test "can't retrieve cached values from different scopes" do
      # GIVEN
      dead_doc = get_dead_doc("/random?scope=one")

      # WHEN
      live_doc = get_live_doc("/random?scope=two", dead_doc)

      # THEN
      refute get_random(dead_doc) == get_random(live_doc)
    end

    test "applies a session scope to a cached value" do
      # GIVEN
      dead_doc = get_dead_doc("/my/random")

      # WHEN
      live_doc = get_live_doc("/random", dead_doc)
      my_live_doc = get_live_doc("/my/random", dead_doc)

      # THEN
      refute get_random(dead_doc) == get_random(live_doc)
      refute get_random(dead_doc) == get_random(my_live_doc)
    end
  end

  describe "assign_cached_new/4" do
    test "persists a value in the cache, falling back to the existing assign value" do
      # GIVEN
      dead_doc =
        build_conn()
        |> Plug.Conn.assign(:random, 123)
        |> get_dead_doc("/random?new=true")

      # WHEN
      live_doc =
        build_conn()
        |> Plug.Conn.assign(:random, 456)
        |> get_live_doc("/random?new=true", dead_doc)

      # THEN
      assert get_random(dead_doc) == "123"
      refute get_random(live_doc) == "456"
      assert get_random(dead_doc) == get_random(live_doc)
    end
  end

  defp get_random(doc) do
    doc |> Floki.find("[data-test-random]") |> Floki.text()
  end

  defp get_dead_doc(conn \\ build_conn(), path) do
    conn
    |> get(path)
    |> html_response(200)
    |> Floki.parse_document!()
  end

  defp get_live_doc(conn \\ build_conn(), path, dead_doc) do
    [cache_key] =
      dead_doc
      |> Floki.find("meta[name=live-cache-key]")
      |> Floki.attribute("content")

    {:ok, _view, live_html} =
      conn
      |> put_connect_params(%{"live_cache_key" => cache_key})
      |> live(path)

    Floki.parse_document!(live_html)
  end
end

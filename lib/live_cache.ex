defmodule LiveCache do
  @moduledoc """
  Briefly cache LiveView assigns to prevent recalculating them during connected mounts.

  By using `assign_cached/4`, an assign evaluated during the disconnected mount
  of a LiveView is temporarily cached in ETS, for retrieval during the connected mount that
  immediately follows.

      def mount(_params, _session, socket) do
        socket = assign_cached(socket, :users, fn ->
          Accounts.list_users()
        end)

        {:ok, socket}
      end

  Cached values are not stored for very long. The cache is invalidated as soon as the connected
  mount occurs, or after 5 seconds (configurable), whichever comes first. In the event of a
  cache miss, the function is evaluated again.

  Live navigation to the LiveView will always result in a cache miss.

  For assigns that depend on external parameters, the `:scope` option can be used to guarantee
  uniqueness of the stored value.

      def mount(%{"id" => id}, _session, socket) do
        socket = assign_cached(socket, :post, scope: id, fn ->
          Blog.get_post(id)
        end)

        {:ok, socket}
      end

  The cache is rehydrated by storing a one-time key in a `<meta>` tag in the DOM, which is
  then passed as a connection param when the `LiveSocket` client connects. For enhanced security,
  the cached values can also be scoped to the current session with the `LiveCache.PerSession` plug.

  ## Installation

  Add `live_cache` to your list of dependencies in `mix.exs`:

      def deps do
        [
          {:live_cache, "~> 0.1.0"}
        ]
      end

  In `my_app_web.ex`, add `on_mount LiveCache` to the `live_view` definition.

      defmodule MyAppWeb do
        def live_view do
          quote do
            # [...]
            on_mount LiveCache
          end
        end
      end

  In the root template `root.html.heex`, add a meta tag to the `<head>`:

  ```html
  <meta name="live-cache-key" content={@live_cache_key} />
  ```

  In `app.js`, modify the `LiveSocket` client constructor to include the value from the meta tag:

  ```js
  let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  let liveCacheKey = document.querySelector("meta[name='live-cache-key']").getAttribute("content");
  let liveSocket = new LiveSocket("/live", Socket, {
    params: { _csrf_token: csrfToken, live_cache_key: liveCacheKey },
  });
  ```

  Finally, add the `LiveCache.PerSession` plug to the router. This step is optional but highly recommended, as it
  ensures that cached values can only be retrieved from the session in which they were stored.

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router

        pipeline :browser do
          # [...]
          plug LiveCache.PerSession
        end


  ## Configuration

  The default config is below.

      config :live_cache,
        expire_after: :timer.seconds(5) # Cache expiration time, in milliseconds;
                                        # set to 0 to disable caching
  """

  alias Phoenix.Component
  alias Phoenix.LiveView

  alias LiveCache.Cache

  @expire_after Application.compile_env(:live_cache, :expire_after, :timer.seconds(5))
  @enabled @expire_after > 0

  @doc """
  LiveView on_mount callback to integrate with LiveCache.

  ## Options

  None.

  ## Example

      on_mount LiveCache
  """
  @spec on_mount(:default, map, map, LiveView.Socket.t()) :: {:cont, LiveView.Socket.t()}
  def on_mount(:default, _params, session, socket) do
    if LiveView.connected?(socket) do
      {:cont, connected_mount(socket, session)}
    else
      {:cont, disconnected_mount(socket, session)}
    end
  end

  defp disconnected_mount(socket, session) do
    # Schedule invalidation during mount, so that if we crash the cache will still be cleaned up
    socket
    |> Component.assign(:live_cache_key, Cache.generate_cache_key())
    |> per_session(session)
    |> invalidate_all_after(@expire_after)
  end

  defp connected_mount(socket, session) do
    socket
    |> Component.assign(:live_cache_key, nil)
    |> per_session(session)
    |> retrieve_cached_assigns()
    |> invalidate_all()
  end

  @doc """
  Put an assign value, populating it from the cache if available.

  On a cache hit during a connected mount, the cached value is used.

  On a cache miss during a connected or disconnected mount, the result of `fun` is used. During the disconnected
  mount, this value is stored in the cache with an expiration.

  ## Options

  - `:scope` - unique conditions to associate with this assign

  ## Examples

      def mount(_params, _session, socket) do
        socket = assign_cached(socket, :address, fn ->
          Accounts.get_address(socket.assigns.current_user)
        end)

        {:ok, socket}
      end

      def handle_params(%{"order_by" => _order_by} = params, _uri, socket) do
        # Only cache the orders list for a specific set of query params
        socket = assign_cached(socket, :orders, scope: params, fn ->
          Orders.list_orders(params)
        end)

        {:noreply, socket}
      end
  """
  @spec assign_cached(LiveView.Socket.t(), atom, keyword, (() -> any)) :: LiveView.Socket.t()
  def assign_cached(socket, key, opts \\ [], fun) do
    do_assign_cached(socket, key, opts, fn socket ->
      Component.assign(socket, key, fun.())
    end)
  end

  @doc """
  Put a new assign value, populating it from the cache if available.

  This function is identical to `assign_cached/4`, except it falls back to
  `Phoenix.Component.assign_new/3` on a cache miss.
  """
  @spec assign_cached_new(LiveView.Socket.t(), atom, keyword, (() -> any)) :: LiveView.Socket.t()
  def assign_cached_new(socket, key, opts \\ [], fun) do
    do_assign_cached(socket, key, opts, fn socket ->
      Component.assign_new(socket, key, fun)
    end)
  end

  defp scope_key(socket, key, opts) do
    {key, socket.private[:live_cache_session], opts[:scope]}
  end

  defp do_assign_cached(socket, key, opts, fallback) do
    # Try to fetch value from cache, falling back to assign_new/3
    socket =
      with {:ok, value} <- fetch_cached_value(socket, key, opts) do
        Component.assign(socket, key, value)
      else
        _ -> fallback.(socket)
      end

    # During disconnected mount, cache it
    if not LiveView.connected?(socket) do
      cache_it(socket, key, opts)
    end

    socket
  end

  defp fetch_cached_value(socket, key, opts) do
    scope_key = scope_key(socket, key, opts)

    with %{private: %{live_cache_assigns: cache}} <- socket,
         {:ok, value} <- Map.fetch(cache, scope_key) do
      {:ok, value}
    else
      _ -> :error
    end
  end

  defp cache_key!(socket) do
    LiveView.get_connect_params(socket)["live_cache_key"] || socket.assigns[:live_cache_key] ||
      raise "live_cache_key unavailable - did you remember to add the meta tag and LiveView socket params?"
  end

  defp invalidate_all_after(socket, timeout) do
    if @enabled do
      Cache.invalidate_all_after(cache_key!(socket), timeout)
    end

    socket
  end

  defp retrieve_cached_assigns(socket) do
    cached_assigns =
      if @enabled do
        Cache.get_cached_assigns(cache_key!(socket))
      else
        %{}
      end

    %{socket | private: Map.put(socket.private, :live_cache_assigns, cached_assigns)}
  end

  defp invalidate_all(socket) do
    # Wipe the cache
    if @enabled do
      Cache.invalidate_all(cache_key!(socket))
    end

    socket
  end

  defp cache_it(socket, key, opts) do
    if @enabled do
      Cache.insert(cache_key!(socket), scope_key(socket, key, opts), socket.assigns[key])
    end

    socket
  end

  defp per_session(socket, session) do
    private = Map.put(socket.private, :live_cache_session, session["live_cache_session"])
    %{socket | private: private}
  end
end

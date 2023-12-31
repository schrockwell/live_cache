# LiveCache

Briefly cache LiveView assigns to prevent recalculating them during connected mounts.

For example:

- Cache a database query to avoid duplicate identical queries, resulting in a faster connected mount
- Cache a random value to determine which content to display in an A/B test

By using `assign_cached/4`, an assign evaluated during the disconnected mount
of a LiveView is temporarily cached in ETS, for retrieval during the connected mount that
immediately follows.

```elixir
def mount(_params, _session, socket) do
  socket = assign_cached(socket, :users, fn ->
    Accounts.list_users()
  end)

  {:ok, socket}
end
```

Cached values are not stored for very long. The cache is invalidated as soon as the connected
mount occurs, or after 5 seconds (configurable), whichever comes first. In the event of a
cache miss, the function is evaluated again.

Live navigation to the LiveView will always result in a cache miss.

The caching of LiveComponent assigns is not currently supported.

## Scoping Cached Values

For assigns that depend on external parameters, the `:scope` option can be used to guarantee
uniqueness of the stored value.

```elixir
def mount(%{"id" => id}, _session, socket) do
  socket = assign_cached(socket, :post, fn -> Blog.get_post(id) end, scope: id)
  {:ok, socket}
end
```

## Implementation Details

The cache is rehydrated by storing a one-time key in a `<meta>` tag in the DOM, which is
then passed as a connection param when the `LiveSocket` client connects. For enhanced security,
the cached values can also be scoped to the current session with the `LiveCache.PerSession` plug.

The cache is stored locally in ETS, and is not distributed. If your production application has
multiple nodes running behind a load balancer, the load balancer must be configured with "sticky
sessions" so that subsequent requests from the same user are handled by the same node.

See HexDoc for [complete documentation](https://hexdocs.pm/live_cache/) and [installation instructions](https://hexdocs.pm/live_cache/LiveCache.html#module-installation).

LiveView 0.18+ is supported.

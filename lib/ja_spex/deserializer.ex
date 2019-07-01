defmodule JaSpex.Deserializer do
  @moduledoc """
  A replacement for Plug `JaSerializer.Deserializer`.

  Add `JaSpex.Deserializer` to your pipeline when you want to
  parse the request parameters as JSON-API _after_ using cast and
  validate from `OpenApiSpex`.

  It replaces `JaSerializer.Deserializer` because OpenApiSpex will
  split the `params` and `body_params` in the conn struct, and the
  base Deserializer only works with params.

  Due to this difference in functionality, `JaSpex.Deserializer`
  should be included in your pipeline _after_ `OpenApiSpex.Plug.Validate`.

  To handle the validation and deserialization in one step, you can use
  `plug(JaSpex)` instead.
  """
  @behaviour Plug
  alias JaSerializer.ParamParser

  @impl Plug
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts \\ []), do: Keyword.take(opts, [:merge_params])

  @impl Plug
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(%Plug.Conn{} = conn, opts) do
    conn
    |> parse_params()
    |> parse_body_params()
    |> maybe_merge_params(opts)
  end

  defp parse_params(conn) do
    params = Enum.into(conn.params, %{}, &cast_param_key/1)

    Map.put(conn, :params, ParamParser.parse(params))
  end

  # Cast param keys back to strings prior to parsing
  defp cast_param_key({k, v}) when is_atom(k), do: {to_string(k), v}
  defp cast_param_key(other), do: other

  defp parse_body_params(conn) do
    Map.put(conn, :body_params, ParamParser.parse(conn.body_params))
  end

  defp maybe_merge_params(conn, merge_params: true) do
    Map.put(conn, :params, Map.merge(conn.params, conn.body_params))
  end

  defp maybe_merge_params(conn, _) do
    conn
  end
end

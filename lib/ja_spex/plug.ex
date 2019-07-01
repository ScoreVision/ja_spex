defmodule JaSpex.Plug do
  @moduledoc """
  A Plug to validate and deserialize OpenAPI requests in JSON-API format.
  """
  alias OpenApiSpex.Plug.CastAndValidate
  alias JaSpex.{Deserializer, RenderError}

  @behaviour Plug

  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts) do
    render_error = Keyword.get(opts, :render_error, RenderError)
    validator_opts = CastAndValidate.init(render_error: render_error)
    deserializer_opts = Deserializer.init(opts)

    [validator: validator_opts, deserializer: deserializer_opts]
  end

  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, opts) do
    conn
    |> CastAndValidate.call(opts[:validator])
    |> Deserializer.call(opts[:deserializer])
  end
end

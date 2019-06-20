defmodule JaSpex.Plug do
  @moduledoc """
  A Plug to validate and deserialize OpenAPI requests in JSON-API format.
  """
  alias OpenApiSpex.Plug.CastAndValidate
  alias JaSpex.{BodyParams, RenderError}

  @behaviour Plug

  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts) do
    opts = Keyword.put_new(opts, :render_error, RenderError)
    validator_opts = CastAndValidate.init(opts)

    [validator: validator_opts]
  end

  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, opts) do
    conn
    |> CastAndValidate.call(opts[:validator])
    |> BodyParams.call()
  end
end

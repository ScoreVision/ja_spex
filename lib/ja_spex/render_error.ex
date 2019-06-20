defmodule JaSpex.RenderError do
  @moduledoc """
  Plug to render errors according to the JSON-API 1.0 specification.

  For more information: https://jsonapi.org/format/#errors
  """
  @behaviour Plug

  import JaSpex, only: [jsonapi: 0]
  alias OpenApiSpex.OpenApi
  alias Plug.Conn

  @impl Plug
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @impl Plug
  def call(conn, errors) when is_list(errors) do
    response = %{
      errors: Enum.map(errors, &render_error/1)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type(jsonapi())
    |> Conn.send_resp(422, json)
  end

  def call(conn, reason) do
    call(conn, [reason])
  end

  defp render_error(error) do
    path = error.path |> Enum.map(&to_string/1) |> Path.join()
    pointer = "/" <> path

    %{
      title: "Invalid value",
      source: %{
        pointer: pointer
      },
      detail: to_string(error)
    }
  end
end

defmodule JaSpex.BodyParams do
  @moduledoc false
  alias JaSerializer.{ParamParser, Params}

  @spec call(Plug.Conn.t()) :: Plug.Conn.t()
  def call(%Plug.Conn{} = conn) do
    parsed_params = parse(conn.body_params)

    Map.put(conn, :body_params, parsed_params)
  end

  defp parse(params) do
    params
    |> ParamParser.parse()
    |> unwrap_parsed_params()
  end

  defp unwrap_parsed_params(%{"data" => data}), do: Params.to_attributes(data)
  defp unwrap_parsed_params(params), do: params
end

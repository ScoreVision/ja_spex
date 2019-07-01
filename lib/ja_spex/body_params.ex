defmodule JaSpex.BodyParams do
  @moduledoc """
  Functions to help with JSON API body params.
  """
  alias JaSerializer.Params

  @spec to_attributes(%{optional(:body_params) => map}) :: map
  def to_attributes(%{body_params: data}), do: Params.to_attributes(data)
  def to_attributes(data), do: Params.to_attributes(data)
end

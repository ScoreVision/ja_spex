defmodule JaSpex do
  @moduledoc """
  A bridge between `OpenApiSpex` and `JaSerializer`.

  Using JaSpex, you can significantly reduce the boilerplate code
  required to validate requests in your Open API format and deserialize
  the data using JaSerializer conventions.
  """

  @content_type "application/vnd.api+json"

  @doc """
  Returns the content type for JSON-API, `"application/vnd.api+json"`.

  ## Examples

      iex> JaSpex.jsonapi()
      "application/vnd.api+json"

  This function is imported when you `use JaSpex.Controller` so it
  can be used as a helper for specifying Open API operations:

      def operation_show do
        %Operation{
          responses: %{
            200 => Operation.response("Show", jsonapi(), Response)
          }
        }
      end
  """
  def jsonapi, do: @content_type

  # Plug callbacks

  defdelegate init(opts), to: JaSpex.Plug
  defdelegate call(conn, opts), to: JaSpex.Plug
end

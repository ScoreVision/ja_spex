defmodule JaSpex.Controller do
  @moduledoc """
  When used, includes action operation behaviours.

  ## Defining Operations

  You define Open API operations as function "headers" in your
  controller.

      def show_operation do
        %Operation{
          tags: ["users"],
          summary: "Show user",
          description: "Show a user by ID",
          operationId: "UserController.show",
          parameters: [
            Operation.parameter(:id, :path, :integer, "User ID", example: 123)
          ],
          responses: %{
            200 => Operation.response("User", jsonapi(), UserResponse)
          }
        }
      end

  If you prefer a different naming convention for you operation functions,
  you can override the `open_api_operation/1` callback.
  """
  @callback open_api_operation(action :: atom()) :: OpenApiSpex.Operation.t()

  defmacro __using__(_opts) do
    quote do
      import JaSpex, only: [jsonapi: 0]
      alias OpenApiSpex.Operation

      @doc """
      Receives an `action` and returns an `t/OpenApiSpex.Operation.t()`.

      To define an operation, create a function named for the action,
      affixed with `"_operation"`. For example, if you are defining
      an operation for the `:show` action, define the operation
      header like so:

          def show_operation do
            %OpenApiSpex.Operation{
              summary: "Show resource"
            }
          end

          def show(conn, params) do
            # regular Phoenix action
          end
      """
      @spec open_api_operation(any) :: Operation.t()
      def open_api_operation(action) do
        operation = String.to_existing_atom("#{action}_operation")
        apply(__MODULE__, operation, [])
      end

      defoverridable open_api_operation: 1
    end
  end
end

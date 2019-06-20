defmodule JaSpex.Controller do
  @moduledoc """
  When used, includes controller operation behaviours.

  ## Defining Operations

  You define Open API operations as function "headers" in your
  controller.

      def operation_show do
        %OpenApiSpex.Operation{
          summary: "Show resource"
        }
      end

  ## Controller Actions

  OpenApiSpex params from the request into path/query params and
  body params. Controllers using JaSpex.Controller
  should implement actions like so:

      def operation_show do
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

  ## Full Example

      defmodule UserController do
        use Phoenix.Controller
        use JaSpex.Controller

        plug JaSpex

        def operation_show do
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

        def show(conn, %{id: user_id}, _body_params) do
          with {:ok, user} <- Users.find_by_id(user_id) do
             conn |> render("show.json-api", data: user)
          end
        end
      end
  """
  @callback open_api_operation(action :: atom()) :: OpenApiSpex.Operation.t()

  defmacro __using__(_opts) do
    quote do
      import JaSpex, only: [jsonapi: 0]
      alias OpenApiSpex.Operation

      @doc """
      Overrides the default action/2 callback for Phoenix controllers.

      When using JaSpex.Controller, define your actions like so:

          @spec show(Plug.Conn.t, map, map) :: Plug.Conn.t
          def show(conn, params, body_params)  do
            # your logic here
          end
      """
      def action(conn, _) do
        apply(__MODULE__, action_name(conn), [conn, conn.params, conn.body_params])
      end

      @doc """
      Receives an `action` and returns an `t/OpenApiSpex.Operation.t()`.

      To define an operation, create a function named for the action,
      prefixed with `"operation_"`. For example, if you are defining
      an operation for the `:show` action, define the operation
      header like so:

          def operation_show do
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
        operation = String.to_existing_atom("operation_#{action}")
        apply(__MODULE__, operation, [])
      end

      defoverridable open_api_operation: 1
    end
  end
end

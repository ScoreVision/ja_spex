# JaSpex

A bridge between [OpenApiSpex](https://hexdocs.pm/open_api_spex) and [JaSerializer](https://hexdocs.pm/ja_serializer)

## Example Controller

```elixir
defmodule UserController do
  use Phoenix.Controller
  # Defines operation callbacks
  use JaSpex.Controller

  # Validates and deserializes request params
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
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ja_spex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ja_spex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ja_spex](https://hexdocs.pm/ja_spex).

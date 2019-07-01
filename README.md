# JaSpex

A bridge between [OpenApiSpex](https://hexdocs.pm/open_api_spex) and [JaSerializer](https://hexdocs.pm/ja_serializer)

## Installation

Add `ja_spex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ja_spex, git: "https://github.com/ReelCoaches/ja_spex.git", tag: "0.1.0"}
  ]
end
```

## Setup

### ApiSpec (OpenApiSpex)

Setup your ApiSpec module as defined in the [Generate Spec](https://github.com/open-api-spex/open_api_spex#generate-spec) section of the OpenApiSpex docs.

### Schemas (OpenApiSpex)

OpenApiSpex Schemas can be deserialized by JaSerializer when you `use JaSpex`:

    ```elixir
    defmodule UserSchema do
      require OpenApiSpex
      use JaSpex

      OpenApiSpex.schema(...)
    end
    ```

### Controller

Add `plug JaSpex` to cast, validate, and deserialize your requests:

```elixir
defmodule MyWeb.ImageController do
  use Phoenix.Controller

  plug(JaSpex)

  # ...
end
```

## Additional Considerations

### DateTime properties

If you specify a property with a `:date-time` format in your schema, OpenApiSpex
will cast its value to a `DateTime` struct. If you would like the values to be
returned in another format, you can implement the `JaSerializer.ParamParser`
protocol for DateTime:

```elixir
defimpl JaSerializer.ParamParser, for: DateTime do
  def parse(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
```


## Examples


### Phoenix.Router

```elixir
  pipeline :api do
    plug(:accepts, ["json-api"])
    plug(OpenApiSpex.Plug.PutApiSpec, module: MyWeb.ApiSpec)
    plug(JaSerializer.ContentTypeNegotiation)
  end
```

### Phoenix.Controller

```elixir
defmodule MyWeb.ImageController do
  use Phoenix.Controller
  # Defines operation callbacks
  use JaSpex.Controller

  # Validates and deserializes request params
  plug JaSpex

  def show_operation do
    import Operation
    alias MyWeb.Schemas.ImageResponse

    %Operation{
      tags: ["images"],
      summary: "Show image",
      description: "Returns information about an image by its ID",
      operationId: "ImageController.show",
      parameters: [
        parameter(:id, :path, :integer, "Image ID", example: 123)
      ],
      responses: %{
        200 => response("Image", JaSpex.jsonapi(), ImageResponse)
      }
    }
  end

  def show(conn, %{"id" => image_id}) do
    with {:ok, user} <- Users.find_by_id(user_id) do
        conn |> render("show.json-api", data: user)
    end
  end
end
```

### Schemas

```elixir
defmodule MyWeb.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule Image do
    use JaSpex, no_parse_fields: [:exif]

    OpenApiSpex.schema(%{
      title: "Image",
      description: "An image file",
      type: :object,
      properties: %{
        name: %Schema{
          type: :string,
          description: "Image filename"
        },
        width: %Schema{
          type: :integer,
          description: "Image width in pixels"
        },
        height: %Schema{
          type: :integer,
          description: "Image height in pixels"
        },
        takenAt: %Schema{
          type: :string,
          description: "The creation datetime of the image",
          format: :"date-time"
        },
        exif: %Schema{
          type: :object,
          additionalProperties: %Schema{
            type: :string
          }
        }
      },
      required: [:name, :width, :height],
      additionalProperties: false,
      example: %{
        "name" => "foo_thumbnail.jpg",
        "width" => 64,
        "height" => 64,
        "takenAt" => "2017-09-13T10:11:12Z",
        "exif" => %{
          "model" => "Canon 5D",
          "creationTimestamp" => "2017-09-13T10:11:12Z"
        }
      }
    })
  end

  defmodule ImageResponse do
    use JaSpex

    OpenApiShema.schema(%{
      title: "ImageResponse",
      description: "An image response object in JSON:API format",
      type: :object,
      properties: %{
        data: %Schema{
          type: :object,
          properties: %{
            id: %Schema{
              type: :integer,
              example: 12345
            },
            type: %Schema{
              type: :string,
              example: "images"
            },
            attributes: Image
          },
          required: [:id, :type, :attributes]
        },
        links: %Schema{
          type: :object,
          properties: %{
            self: %Schema{
              type: :string,
              format: :uri,
              example: "https://localhost:4000/images/12345"
            }
          }
        }
      },
      example: %{
        "data" => %{
          "type" => "images",
          "attributes" => Image.schema().example,
          "id" => 123456
        }
      }
    })
  end
end
```

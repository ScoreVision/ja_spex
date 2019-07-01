defmodule JaSpexTest.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule ImageBase do
    defmacro __using__(_opts) do
      quote do
        OpenApiSpex.schema(%{
          title: "Image",
          description: "An image file",
          type: :object,
          properties: %{
            name: %Schema{type: :string, description: "Image name"},
            width: %Schema{type: :integer, description: "Image width in pixels"},
            height: %Schema{type: :integer, description: "Image height in pixels"},
            takenAt: %Schema{
              type: :string,
              description: "The creation datetime of the image",
              format: :"date-time"
            },
            exif: %Schema{type: :object, additionalProperties: %Schema{type: :string}}
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
    end
  end

  defmodule Image do
    use ImageBase
    use JaSpex
  end

  defmodule ImageOnlyName do
    use ImageBase
    use JaSpex, only: [:name]
  end

  defmodule ImageNoExif do
    use ImageBase
    use JaSpex, except: [:exif]
  end

  defmodule ImageNoParseExif do
    use ImageBase
    use JaSpex, no_parse_fields: [:exif]
  end

  defmodule ImageNaiveDateTime do
    use ImageBase
    use JaSpex

    from_schema(schema) do
      schema
      |> Map.update!(:takenAt, &DateTime.to_naive/1)
    end
  end
end

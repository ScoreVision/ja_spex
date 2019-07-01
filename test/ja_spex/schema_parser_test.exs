defmodule JaSpex.SchemaParserTest do
  use ExUnit.Case
  alias JaSerializer.ParamParser
  alias JaSpexTest.Schemas

  setup _ do
    timestamp = "2017-09-13T10:11:12Z"

    {:ok, datetime, _} = DateTime.from_iso8601(timestamp)

    schema_data = %{
      name: "foo_thumbnail.jpg",
      width: 64,
      height: 64,
      takenAt: datetime,
      exif: %{
        "camera" => "Canon 5D",
        "creationTimestamp" => timestamp
      }
    }

    {:ok, schema_data: schema_data}
  end

  describe "implements JaSerializer.ParamParser" do
    test "without default options", %{schema_data: schema_data} do
      image = struct(Schemas.Image, schema_data)

      assert %{} = data = ParamParser.parse(image)

      # Assert string keys
      Enum.each(data, fn {k, _v} -> assert is_binary(k) end)

      # Assert key format
      struct_keys = Map.keys(image) -- [:__struct__]

      Enum.each(struct_keys, fn key ->
        formatted_key = JaSerializer.ParamParser.Utils.format_key(key)
        assert Map.has_key?(data, formatted_key)
      end)
    end

    test "with `:only` option for `:name`", %{schema_data: schema_data} do
      image = struct(Schemas.ImageOnlyName, schema_data)

      assert %{} = data = ParamParser.parse(image)

      assert data == %{"name" => "foo_thumbnail.jpg"}
    end

    test "with `:except` option for `:exif`", %{schema_data: schema_data} do
      image = struct(Schemas.ImageNoExif, schema_data)

      assert %{} = data = ParamParser.parse(image)

      refute Map.has_key?(data, "exif")
    end

    test "with `:no_parse_fields` option for `:exif`", %{schema_data: schema_data} do
      image = struct(Schemas.ImageNoParseExif, schema_data)

      assert %{} = data = ParamParser.parse(image)

      assert get_in(data, ["exif", "creationTimestamp"])
    end

    test "with from_schema/2", %{schema_data: schema_data} do
      image = struct(Schemas.ImageNaiveDateTime, schema_data)

      assert %{} = data = ParamParser.parse(image)

      assert %NaiveDateTime{} = data["taken_at"]
    end
  end
end

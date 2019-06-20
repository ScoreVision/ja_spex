defmodule JaSpex.SchemaParser do
  @moduledoc false

  defmacro __compile_parser__(%{module: mod}, _) do
    parser_opts = mod.__parser_opts__()
    schema = mod.schema()
    allowed_fields = build_allowed_fields(schema.properties, parser_opts)
    no_parse_fields = Keyword.get(parser_opts, :no_parse_fields, [])

    quote do
      defimpl JaSerializer.ParamParser, for: unquote(mod) do
        alias JaSerializer.ParamParser, as: JaParser

        def parse(data) do
          data
          |> Map.delete(:__struct__)
          |> Map.take(unquote(allowed_fields))
          |> unquote(mod).__from_schema__()
          |> Map.split(unquote(no_parse_fields))
          |> parse_and_merge()
        end

        defp parse_and_merge({non_parsed_fields, to_parse_fields}) do
          to_parse_fields
          |> parse_value()
          |> Map.merge(format_keys(non_parsed_fields))
        end

        defp format_keys(map) when is_map(map), do: Map.new(map, &format_key/1)

        defp format_key({key, value}), do: {format_key(key), value}
        defp format_key(key) when is_atom(key), do: format_key(to_string(key))
        defp format_key(key) when is_binary(key), do: JaParser.Utils.format_key(key)

        defp parse_pair({key, value}), do: {format_key(key), parse_value(value)}

        defp parse_value(%{__struct__: _} = struct), do: JaParser.parse(struct)
        defp parse_value(value) when is_map(value), do: Map.new(value, &parse_pair/1)
        defp parse_value(value) when is_list(value), do: Enum.map(value, &parse_value/1)
        defp parse_value(value), do: JaParser.parse(value)
      end
    end
  end

  defp build_allowed_fields(allowed, opts) when is_map(allowed),
    do: build_allowed_fields(Map.keys(allowed), opts)

  defp build_allowed_fields(allowed, opts) when is_list(allowed) do
    cond do
      opts[:only] -> opts[:only] -- opts[:only] -- allowed
      opts[:except] -> allowed -- opts[:except]
      true -> allowed
    end
  end
end

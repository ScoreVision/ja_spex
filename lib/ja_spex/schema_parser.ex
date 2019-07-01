defmodule JaSpex.SchemaParser do
  @moduledoc """
  An implementation of the `JaSerializer.ParamParser` protocol for generated schemas.

  When used the `JaSpex.SchemaParser` module will generate a ParamParser
  implementation that matches the current schema.

  You can optionally whitelist or blacklist certain fields using the
  `:only` and `:except` options. Any fields outside of those defined
  in the Schema properties will be automatically ignored.

  **No parse fields**

  There may be some fields in your schema that you do not want parsed:
  these fields may contain data the user expects to be returned in a
  specific format. In these cases, specify the keys to ignore in the
  `:no_parse_fields` option. For example, if your schema contained
  an opaque `metadata` field:

      defmodule ImageSchema do
        require OpenApiSpex

        use JaSpex, no_parse_fields: [:metadata]

        OpenApiSpex.schema(%OpenApiSpex.Schema{
          type: :object,
          properties: %{
            metadata: %OpenApiSpex.Schema{
              type: :object,
              additionalProperties: true
            }
          }
        })
      end
  """

  @doc false
  # Not to be directly implemented, use the `from_schema/2` macro instead
  @callback __from_schema__(data :: map) :: map

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      require JaSpex.SchemaParser
      import JaSpex.SchemaParser, only: [from_schema: 2]
      @behaviour JaSpex.SchemaParser

      @parser_opts opts

      def __from_schema__(schema), do: schema

      defoverridable __from_schema__: 1

      @before_compile JaSpex.SchemaParser
    end
  end

  defmacro from_schema(param, do: block) do
    quote do
      def __from_schema__(unquote(param)) do
        import JaSpex.SchemaParser, except: [from_schema: 2, __compile_parser__: 2]
        unquote(block)
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @after_compile {JaSpex.SchemaParser, :__compile_parser__}

      def __parser_opts__, do: @parser_opts
    end
  end

  defmacro __compile_parser__(%{module: mod}, _) do
    parser_opts = mod.__parser_opts__()
    schema = mod.schema()
    allowed_fields = build_allowed_fields(schema.properties, parser_opts)
    no_parse_fields = Keyword.get(parser_opts, :no_parse_fields, [])

    quote bind_quoted: [
            mod: mod,
            allowed_fields: allowed_fields,
            no_parse_fields: no_parse_fields
          ] do
      defimpl JaSerializer.ParamParser, for: mod do
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

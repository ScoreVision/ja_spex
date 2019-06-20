defmodule JaSpex.Deserializer do
  @moduledoc """
  When used on a Schema, deserializes derived structs into attribute maps.
  """

  @doc false
  # Not to be directly implemented, use the `from_schema/2` macro instead
  @callback __from_schema__(data :: map) :: map

  @doc false
  defmacro __using__(opts \\ []) do
    quote do
      require JaSpex.Deserializer
      import JaSpex.Deserializer, only: [from_schema: 2]
      @behaviour JaSpex.Deserializer

      @doc false
      def __parser_opts__, do: unquote(opts)

      def __from_schema__(schema), do: schema

      defoverridable __from_schema__: 1

      @after_compile {JaSpex.SchemaParser, :__compile_parser__}
    end
  end

  defmacro from_schema(param, do: block) do
    quote do
      def __from_schema__(unquote(param)) do
        import JaSpex.Deserializer, except: [from_schema: 2]
        unquote(block)
      end
    end
  end

  @doc """
  Casts a datetime from the `field` to the given `type`.

  ## Examples

      iex> %{a: DateTime.from_naive!(~N[2015-01-13 13:00:07.987654], "Etc/UTC")}
      ...> |> JaSpex.Deserializer.cast_datetime(:a, :naive_datetime)
      %{a: ~N[2015-01-13 13:00:07]}

      iex> %{a: DateTime.from_naive!(~N[2015-01-13 13:00:07.123456], "Etc/UTC")}
      ...> |> JaSpex.Deserializer.cast_datetime(:a, :naive_datetime_usec)
      %{a: ~N[2015-01-13 13:00:07.123456]}
  """
  def cast_datetime(data, field, type)

  def cast_datetime(%{} = data, key, type) do
    key = List.wrap(key)
    maybe_update_in(data, key, maybe(&cast_datetime_to(&1, type)))
  end

  defp cast_datetime_to(%DateTime{} = datetime, type) when is_atom(type),
    do: datetime_to(datetime, type)

  defp cast_datetime_to(value, _), do: value

  defp datetime_to(datetime, :naive_datetime) do
    naive_datetime = DateTime.to_naive(datetime)

    %{naive_datetime | microsecond: {0, 0}}
  end

  defp datetime_to(datetime, :naive_datetime_usec) do
    DateTime.to_naive(datetime)
  end

  defp datetime_to(datetime, :utc_datetime) do
    {:ok, utc_datetime} = DateTime.shift_zone(datetime, "Etc/UTC")

    %{utc_datetime | microsecond: {0, 0}}
  end

  defp datetime_to(datetime, :utc_datetime_usec) do
    {:ok, utc_datetime} = DateTime.shift_zone(datetime, "Etc/UTC")

    utc_datetime
  end

  defp maybe(fun) do
    fn
      nil -> nil
      arg -> fun.(arg)
    end
  end

  defp maybe_update_in(data, path, fun) do
    case get_in(data, path) do
      nil -> data
      val -> put_in(data, path, fun.(val))
    end
  end
end

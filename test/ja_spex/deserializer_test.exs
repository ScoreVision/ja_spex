defmodule JaSpex.DeserializerTest do
  use ExUnit.Case
  use Plug.Test

  defmodule SplitParams do
    @behaviour Plug

    @impl Plug
    def init(opts \\ []), do: opts

    # Emulates OpenApiSpex splitting the params
    @impl Plug
    def call(conn, _opts) do
      conn
      |> Plug.Conn.fetch_query_params()
      |> Map.update!(:params, fn params ->
        Map.drop(params, Map.keys(conn.body_params))
      end)
    end
  end

  defmodule MyPlug do
    use Plug.Builder

    plug(SplitParams)
    plug(JaSpex.Deserializer)
  end

  defmodule MyMergePlug do
    use Plug.Builder

    plug(SplitParams)
    plug(JaSpex.Deserializer, merge_params: true)
  end

  test "parses params" do
    conn = conn(:get, "/?myParam=10")

    conn = MyPlug.call(conn, MyPlug.init([]))

    assert %{"my_param" => _} = conn.params
  end

  test "parses body params" do
    conn = conn(:post, "/?myParam=10", %{"data" => %{"attributes" => %{"firstName" => "Aaron"}}})

    conn = MyPlug.call(conn, MyPlug.init([]))

    assert get_in(conn.body_params, ["data", "attributes", "first_name"])
  end

  test "with merge_params: true, merges params and body_params" do
    conn = conn(:post, "/?myParam=10", %{"data" => %{"attributes" => %{"name" => "foo"}}})

    conn = MyMergePlug.call(conn, MyMergePlug.init([]))

    assert %{"my_param" => _, "data" => _} = conn.params
  end
end

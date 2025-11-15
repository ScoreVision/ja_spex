defmodule JaSpex.RenderErrorTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias JaSpex.RenderError

  describe "call/2 with empty path errors" do
    test "handles error with empty path (root-level validation error)" do
      # This simulates OpenApiSpex errors for root-level failures
      # such as type mismatches at the root level
      error = %OpenApiSpex.Cast.Error{
        name: nil,
        path: [],
        reason: :invalid_type,
        type: :object,
        value: "not an object"
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      assert conn.status == 422
      assert get_resp_header(conn, "content-type") == ["application/vnd.api+json; charset=utf-8"]

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      assert error_obj["title"] == "Invalid value"
      assert error_obj["source"]["pointer"] == "/"
      assert is_binary(error_obj["detail"])
    end

    test "handles multiple errors with empty paths" do
      errors = [
        %OpenApiSpex.Cast.Error{
          name: nil,
          path: [],
          reason: :invalid_type,
          type: :object,
          value: []
        },
        %OpenApiSpex.Cast.Error{
          name: "data",
          path: [],
          reason: :missing_field,
          value: %{}
        }
      ]

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, errors)

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => error_list} = body
      assert length(error_list) == 2
      assert Enum.all?(error_list, fn e -> e["source"]["pointer"] == "/" end)
    end
  end

  describe "call/2 with nested path errors" do
    test "handles error with single element path" do
      error = %OpenApiSpex.Cast.Error{
        name: "type",
        path: ["data"],
        reason: :invalid_type,
        value: nil
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      assert error_obj["title"] == "Invalid value"
      assert error_obj["source"]["pointer"] == "/data"
      assert is_binary(error_obj["detail"])
    end

    test "handles error with nested path" do
      error = %OpenApiSpex.Cast.Error{
        name: "email",
        path: ["data", "attributes", "email"],
        reason: :invalid_format,
        value: "not-an-email"
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      assert error_obj["title"] == "Invalid value"
      assert error_obj["source"]["pointer"] == "/data/attributes/email"
      assert is_binary(error_obj["detail"])
    end

    test "handles error with deeply nested path" do
      error = %OpenApiSpex.Cast.Error{
        name: "street",
        path: ["data", "attributes", "address", "billing", "street"],
        reason: :invalid_type,
        value: 123
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      assert error_obj["source"]["pointer"] == "/data/attributes/address/billing/street"
    end
  end

  describe "call/2 with single error" do
    test "handles a single error (not in a list)" do
      error = %OpenApiSpex.Cast.Error{
        name: "id",
        path: ["data", "id"],
        reason: :missing_field,
        value: nil
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, error)

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      assert error_obj["source"]["pointer"] == "/data/id"
    end
  end

  describe "call/2 with mixed errors" do
    test "handles mix of empty and nested path errors" do
      errors = [
        %OpenApiSpex.Cast.Error{
          name: nil,
          path: [],
          reason: :invalid_type,
          type: :object,
          value: "not an object"
        },
        %OpenApiSpex.Cast.Error{
          name: "email",
          path: ["data", "attributes", "email"],
          reason: :invalid_format,
          value: "bad-email"
        }
      ]

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, errors)

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error1, error2]} = body
      assert error1["source"]["pointer"] == "/"
      assert error2["source"]["pointer"] == "/data/attributes/email"
    end
  end

  describe "call/2 response format" do
    test "returns proper JSON:API error response structure" do
      error = %OpenApiSpex.Cast.Error{
        name: "type",
        path: ["data", "type"],
        reason: :invalid_enum,
        value: "wrong-type"
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      assert conn.status == 422
      assert get_resp_header(conn, "content-type") == ["application/vnd.api+json; charset=utf-8"]

      {:ok, body} = Jason.decode(conn.resp_body)

      # Verify JSON:API structure
      assert Map.has_key?(body, "errors")
      assert is_list(body["errors"])

      [error_obj] = body["errors"]
      assert Map.has_key?(error_obj, "title")
      assert Map.has_key?(error_obj, "detail")
      assert Map.has_key?(error_obj, "source")
      assert Map.has_key?(error_obj["source"], "pointer")
    end
  end

  describe "edge cases" do
    test "handles error with numeric path elements" do
      error = %OpenApiSpex.Cast.Error{
        name: "item",
        path: ["data", 0, "attributes", "name"],
        reason: :invalid_type,
        value: nil
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      assert conn.status == 422

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      # Path.join should convert all elements to strings
      assert error_obj["source"]["pointer"] == "/data/0/attributes/name"
    end

    test "handles error detail with various error reasons" do
      error = %OpenApiSpex.Cast.Error{
        name: "age",
        path: ["data", "attributes", "age"],
        reason: :maximum,
        value: 200
      }

      conn = conn(:post, "/api/resource")
      conn = RenderError.call(conn, [error])

      {:ok, body} = Jason.decode(conn.resp_body)

      assert %{"errors" => [error_obj]} = body
      assert is_binary(error_obj["detail"])
      assert String.length(error_obj["detail"]) > 0
    end
  end
end

defmodule JaSpexTest do
  use ExUnit.Case
  doctest JaSpex

  test "returns the content type" do
    assert JaSpex.jsonapi() == "application/vnd.api+json"
  end
end

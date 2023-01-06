defmodule JaSpex.MixProject do
  use Mix.Project

  @github_url "https://github.com/ReelCoaches/ja_spex"

  def project do
    [
      app: :ja_spex,
      version: "0.1.0",
      source_url: @github_url,
      homepage_url: @github_url,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: Mix.env() != :test
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:open_api_spex, "~> 3.16"},
      {:ja_serializer, "~> 0.17"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end

defmodule JSONPatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :json_patch,
      description: "An Elixir implementation of JSON Patch (RFC 6902)",
      package: package(),
      version: "0.8.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["pete gamache <pete@gamache.org>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/gamache/json_patch_elixir",
        "Docs" => "https://hexdocs.pm/json_patch"
      }
    ]
  end

  defp aliases do
    [
      docs: "docs --source-url https://github.com/gamache/json_patch_elixir",
      "download-tests": [&download_tests/1]
    ]
  end

  defp download_tests(_) do
    {_, 0} =
      System.cmd("git", [
        "clone",
        "https://github.com/json-patch/json-patch-tests.git",
        "test/json-patch-tests"
      ])
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev},
      {:jason, "~> 1.0", only: :test},
      {:ex_spec, "~> 2.0", only: :test},
      {:excoveralls, "~> 0.8", only: :test},
    ]
  end
end

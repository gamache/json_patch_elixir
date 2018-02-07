defmodule JSONPatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :json_patch,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp aliases do
    [
      "download-tests": [&download_tests/1]
    ]
  end

  defp download_tests(_) do
    {_, 0} = System.cmd("git", [
      "clone",
      "https://github.com/json-patch/json-patch-tests.git",
      "test/json-patch-tests",
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
      {:ex_spec, "~> 2.0", only: :test},
      {:ex_doc, "~> 0.18", only: :dev},
      {:jason, "~> 1.0", only: :test},
    ]
  end
end
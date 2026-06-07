defmodule Furlex.MixProject do
  use Mix.Project

  @version "0.5.0"
  @source_url "https://github.com/XukuLLC/furlex"

  def project do
    [
      app: :furlex,
      version: @version,
      elixir: "~> 1.20",
      description: description(),
      package: package(),
      deps: deps(),
      name: "Furlex",
      source_url: @source_url,
      aliases: aliases(),
      docs: [
        main: "Furlex",
        source_ref: "v#{@version}",
        source_url: @source_url,
        extras: ~w(README.md CHANGELOG.md)
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
        check: :test,
        "test.watch": :test
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      mod: {Furlex, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:floki, "~> 0.36.0"},
      {:jason, "~> 1.4", optional: true},
      {:plug, "~> 1.16"},
      {:req, "~> 0.5"},
      {:benchee, "~> 1.3", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:bypass, "~> 2.1.0", only: :test},
      {:html_entities, "~> 0.5"},
      {:mix_test_watch, "~> 1.4", only: :dev, runtime: false},
      {:quokka, "~> 2.12", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Furlex is a structured data extraction tool written in Elixir.

    It currently supports unfurling oEmbed, Twitter Card, Facebook Open Graph, JSON-LD
    and plain ole' HTML `<meta />` data out of any url you supply.
    """
  end

  defp package do
    [
      name: :furlex,
      files: ~w(doc lib mix.exs README.md LICENSE.md CHANGELOG.md),
      maintainers: ["Neil Berkman"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/furlex"
      }
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --strict",
        "dialyzer --format short",
        "test"
      ]
    ]
  end
end

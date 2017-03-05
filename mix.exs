defmodule Songalize.Mixfile do
  use Mix.Project

  def project do
    [app: :songalize,
     escript: escript_config(),
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end

  defp escript_config do
    [main_module: Songalize.CLI]
  end
end

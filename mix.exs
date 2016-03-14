
defmodule Promenade.Mixfile do
  use Mix.Project

  def project do
    [
      app: :promenade,
      version: "0.0.1",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger],
      mod: {Promenade, []},
      env: [
        http_port: 8080,
        udp_port: 8126,
      ],
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      exrm: "~> 0.18.1",
      exactor: "~> 2.2.0",
      plug: "~> 1.1.2",
      cowboy: "~> 1.0.0",
    ]
  end
end

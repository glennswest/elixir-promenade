
defmodule Promenade.Mixfile do
  use Mix.Project

  def project do
    [
      app: :promenade,
      version: "0.4.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
    ]
  end

  def application do
    [
      applications: [
        :logger,
        :flasked,
        :plug,
        :cowboy,
        :gpb,
        :exprotobuf,
        :quantile_estimator
      ],
      mod: {Promenade, []},
      env: [
        http_port: 8080,
        udp_port: 8126,
      ],
    ]
  end

  defp deps do
    [
      {:distillery, "~> 0.10.0"},
      {:flasked,    "~> 0.4.0"},
      {:exactor,    "~> 2.2.0", warn_missing: false},
      {:plug,       "~> 1.3.0"},
      {:cowboy,     "~> 1.0.0"},
      {:gpb,        "~> 3.26.6"},
      {:exprotobuf, "~> 1.2.5"},
      {:quantile_estimator,
        git: "https://github.com/jemc/quantile_estimator.git",
        sha: "37f4d6cc5808dc6c571563c3b76ca1a71b7cff3e",
      },
    ]
  end
end

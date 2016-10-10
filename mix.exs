
defmodule Promenade.Mixfile do
  use Mix.Project

  def project do
    [
      app: :promenade,
      version: "0.2.0",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
    ]
  end

  def application do
    [
      applications: [
        :logger,
        :plug,
        :cowboy,
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
      {:exrm, "~> 1.0.2"},
      {:exactor, "~> 2.2.0", warn_missing: false},
      {:plug, "~> 1.2.2"},
      {:cowboy, "~> 1.0.0"},
      {:quantile_estimator,
        git: "https://github.com/jemc/quantile_estimator.git",
        sha: "37f4d6cc5808dc6c571563c3b76ca1a71b7cff3e",
      },
    ]
  end
end

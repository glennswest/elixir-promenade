# Promenade

[![CI Status](https://circleci.com/gh/jemc/elixir-promenade.svg?style=shield)](https://circleci.com/gh/jemc/elixir-promenade)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/jemc/elixir-promenade.svg)](https://beta.hexfaktor.org/github/jemc/elixir-promenade)

A metrics forwarder for Prometheus that accepts UDP input in a format similar to StatsD, but with support for the proper Prometheus data model, including labels.

Conceptually, this is a best-of-both-worlds between the [official Prometheus StatsD Exporter](https://github.com/prometheus/statsd_exporter) (which does not support the proper Prometheus data model) and the [official Prometheus Push Gateway](https://github.com/prometheus/pushgateway) (which supports only synchronous HTTP input and has a limited jobs-based orientation).

Unlike both of those other solutions, Promenade *is* intended for long-term use, because it fills a need not met by any official solution.

Promenade is suitable for:

* Services that are *not* web servers, and thus cannot expose an HTTP endpoint for Prometheus to scrape.
* Web servers that are forking (like [Unicorn](http://unicorn.bogomips.org/)), and thus cannot be reliably scraped by Prometheus.
* Web servers in complex deployment schemes that make it impractical for Prometheus to scrape all of the servers.
* Services that are currently using StatsD and want to minimally change their implementation while also getting support for the full Prometheus data model.
* Services whose developers are not sold on the Prometheus pull model of metrics and are frustrated by the paradigm of the official solutions.

## Running Promenade

In many cases, the easiest way to run Promenade as a standalone service is with Docker, for which [an official image is provided as an automated build](https://hub.docker.com/r/jemc/promenade):

```shell
# Run promenade, exposing the UDP input on port 8126 and HTTP output on 8080.
docker run -p 8126:8126 -p 8080:8080 -d jemc/promenade
```

## Sending Metrics to Promenade over UDP

Just like with StatsD, metrics are received by Promenade as UDP packets. The default UDP listener port is `8126`.

In order to ease transition from StatsD-based instrumentation, Promenade accepts input in a format that is very similar to the [StatsD input format](https://github.com/etsy/statsd/blob/master/docs/metric_types.md). That is, each UDP packet should contain one or more lines that look like the following, separated by "newline" characters (`\n`):

```
my_metric_name:88.8|g
my_metric_name{label1="FOO",label2="bar"}:99.9|g
```

More generally, a metric line should consist of:

* a name (following the Prometheus [best practices for naming metrics](https://prometheus.io/docs/practices/naming/))
* optionally followed by a group of one or more labels (in the same format as in the Prometheus [text exposition format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-format-details))
* followed by a colon character (`:`)
* followed by a value that can be parsed as a floating point number
* followed by a pipe character (`|`)
* followed by a single "suffix" character that corresponds to the [metric type](#metric-types) (`g`, `c`, or `s`).

### Metric Types (by suffix)

* `|g` - [Gauge](https://prometheus.io/docs/concepts/metric_types/#gauge) - an instantaneous measurement of the definitive, absolute value of something.
* `|c` - [Counter](https://prometheus.io/docs/concepts/metric_types/#counter) - a measurement of the relative increase of something.
* `|s` - [Summary](https://prometheus.io/docs/concepts/metric_types/#summary) - a single sample measurement from a distribution of samples of something.
* `|h` - [Histogram](https://prometheus.io/docs/concepts/metric_types/#histogram) - *NOT YET SUPPORTED*.

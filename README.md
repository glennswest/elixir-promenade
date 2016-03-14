# Promenade

A metrics forwarder for Prometheus that accepts UDP input in a format similar to StatsD, but with support for the proper Prometheus data model, including labels.

Conceptually, this is a best-of-both-worlds between the [official Prometheus StatsD Exporter](https://github.com/prometheus/statsd_exporter) (which does not support the proper Prometheus data model) and the [official Prometheus Push Gateway](https://github.com/prometheus/pushgateway) (which supports only synchronous HTTP input and has a limited jobs-based orientation).

Unlike both of those other solutions, Promenade *is* intended for long-term use, because it fills a need not met by any official solution.

Promenade is suitable for:

* Services that are *not* web servers, and thus cannot expose an HTTP endpoint for Prometheus to scrape.
* Web servers that are forking (like [Unicorn](http://unicorn.bogomips.org/)), and thus cannot be reliably scraped by Prometheus.
* Web servers in complex deployment schemes that make it impractical for Prometheus to scrape all of the servers.
* Services that are currently using StatsD and want to minimally change their implementation while also getting support for the full Prometheus data model.
* Services whose developers are not sold on the Prometheus pull model of metrics and are frustrated by the paradigm of the official solutions.

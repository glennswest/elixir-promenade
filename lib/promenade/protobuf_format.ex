
defmodule Promenade.ProtobufFormat do
  defmodule Messages do
    # From https://raw.githubusercontent.com/prometheus/client_model/086fe7ca28bde6cec2acd5223423c1475a362858/metrics.proto
    use Protobuf, """
      // Copyright 2013 Prometheus Team
      // Licensed under the Apache License, Version 2.0 (the "License");
      // you may not use this file except in compliance with the License.
      // You may obtain a copy of the License at
      //
      // http://www.apache.org/licenses/LICENSE-2.0
      //
      // Unless required by applicable law or agreed to in writing, software
      // distributed under the License is distributed on an "AS IS" BASIS,
      // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      // See the License for the specific language governing permissions and
      // limitations under the License.

      syntax = "proto2";

      package io.prometheus.client;
      option java_package = "io.prometheus.client";

      message LabelPair {
        optional string name  = 1;
        optional string value = 2;
      }

      enum MetricType {
        COUNTER    = 0;
        GAUGE      = 1;
        SUMMARY    = 2;
        UNTYPED    = 3;
        HISTOGRAM  = 4;
      }

      message Gauge {
        optional double value = 1;
      }

      message Counter {
        optional double value = 1;
      }

      message Quantile {
        optional double quantile = 1;
        optional double value    = 2;
      }

      message Summary {
        optional uint64   sample_count = 1;
        optional double   sample_sum   = 2;
        repeated Quantile quantile     = 3;
      }

      message Untyped {
        optional double value = 1;
      }

      message Histogram {
        optional uint64 sample_count = 1;
        optional double sample_sum   = 2;
        repeated Bucket bucket       = 3; // Ordered in increasing order of upper_bound, +Inf bucket is optional.
      }

      message Bucket {
        optional uint64 cumulative_count = 1; // Cumulative in increasing order.
        optional double upper_bound = 2;      // Inclusive.
      }

      message Metric {
        repeated LabelPair label        = 1;
        optional Gauge     gauge        = 2;
        optional Counter   counter      = 3;
        optional Summary   summary      = 4;
        optional Untyped   untyped      = 5;
        optional Histogram histogram    = 7;
        optional int64     timestamp_ms = 6;
      }

      message MetricFamily {
        optional string     name   = 1;
        optional string     help   = 2;
        optional MetricType type   = 3;
        repeated Metric     metric = 4;
      }
    """
  end
  
  alias Promenade.Summary
  alias Messages, as: M
  
  use Bitwise, only_operators: true
  
  def snapshot({gauges, counters, summaries}) do
       section(:GAUGE,   gauges)
    ++ section(:COUNTER, counters)
    ++ section(:SUMMARY, summaries)
  end
  
  defp section(type, metric_families) do
    metric_families
    |> Enum.map(&metric_family(type, &1))
    |> Enum.map(&M.MetricFamily.encode/1)
    |> Enum.map(&[varint(byte_size(&1)), &1])
  end
  
  defp metric_family(type, {name, metrics}) do
    M.MetricFamily.new(
      name:   name,
      type:   type,
      metric: metrics |> Enum.map(&metric(type, &1))
    )
  end
  
  defp metric(:GAUGE, {labels, value}) do
    M.Metric.new(
      label: label_pairs(labels),
      gauge: M.Gauge.new(value: value),
    )
  end
  
  defp metric(:COUNTER, {labels, value}) do
    M.Metric.new(
      label:   label_pairs(labels),
      counter: M.Counter.new(value: value),
    )
  end
  
  defp metric(:SUMMARY, {labels, s}) do
    M.Metric.new(
      label:   label_pairs(labels),
      summary: M.Summary.new(
        sample_count: Summary.count(s),
        sample_sum:   Summary.sum(s),
        quantile: [
          M.Quantile.new(quantile: 0.5,  value: Summary.quantile(s, 0.5)),
          M.Quantile.new(quantile: 0.9,  value: Summary.quantile(s, 0.9)),
          M.Quantile.new(quantile: 0.99, value: Summary.quantile(s, 0.99)),
        ]
      )
    )
  end
  
  defp label_pairs(labels) do
    labels
    |> Enum.map(fn {k, v} -> M.LabelPair.new(name: k, value: v) end)
  end
  
  # Encode the given number as a "varint", returning a binary/string.
  defp varint(n), do: :gpb.encode_varint(n)
end

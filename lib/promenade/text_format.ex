
defmodule Promenade.TextFormat do
  alias Promenade.Summary
  
  def snapshot({gauges, counters, summaries}) do
    section(:gauge,   gauges)   <> "\n" <>
    section(:counter, counters) <> "\n" <>
    section(:summary, summaries)
  end
  
  def section(type, metrics) do
    metrics
    |> Enum.map(&(metric(type, elem(&1, 0), elem(&1, 1))))
    |> Enum.join("\n")
  end
  
  def metric(type, name, entries) do
    "# TYPE #{name} #{type}\n" <> (
      entries
      |> Enum.map(&(entry(type, name, elem(&1, 0), elem(&1, 1))))
      |> Enum.join
    )
  end
  
  def entry(:summary, name, labels, s) do
    ql = "quantile"
    
       entry(nil, name, Map.put(labels, ql, "0.5"),  Summary.quantile(s, 0.5))
    <> entry(nil, name, Map.put(labels, ql, "0.9"),  Summary.quantile(s, 0.9))
    <> entry(nil, name, Map.put(labels, ql, "0.99"), Summary.quantile(s, 0.99))
    <> entry(nil, "#{name}_sum",   labels, Summary.sum(s))
    <> entry(nil, "#{name}_count", labels, Summary.count(s))
  end
  
  def entry(_, name, labels, value) do
    "#{name}#{labels_text(labels)} #{value}\n"
  end
  
  def labels_text(labels) do
    text = labels
           |> Enum.map(&("#{elem(&1, 0)}=\"#{elem(&1, 1)}\""))
           |> Enum.join(",")
    
    (text == "") && "" || "{#{text}}"
  end
end

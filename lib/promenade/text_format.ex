
defmodule Promenade.TextFormat do
  alias Promenade.Summary
  
  def snapshot({gauges, counters, summaries}) do
    section(:gauge,   gauges)   <> "\n" <>
    section(:counter, counters) <> "\n" <>
    section(:summary, summaries)
  end
  
  defp section(type, metric_families) do
    metric_families
    |> Enum.map(&metric_family(type, &1))
    |> Enum.join("\n")
  end
  
  defp metric_family(type, {name, metrics}) do
    "# TYPE #{name} #{type}\n" <> (
      metrics
      |> Enum.map(&metric(type, name, &1))
      |> Enum.join
    )
  end
  
  defp metric(:summary, name, {labels, s}) do
    ql = "quantile"
    
       metric(0, name, {Map.put(labels, ql, "0.5"),  Summary.quantile(s, 0.5)})
    <> metric(0, name, {Map.put(labels, ql, "0.9"),  Summary.quantile(s, 0.9)})
    <> metric(0, name, {Map.put(labels, ql, "0.99"), Summary.quantile(s, 0.99)})
    <> metric(0, "#{name}_sum",   {labels, Summary.sum(s)})
    <> metric(0, "#{name}_count", {labels, Summary.count(s)})
  end
  
  defp metric(_, name, {labels, value}) do
    "#{name}#{labels_text(labels)} #{value}\n"
  end
  
  defp labels_text(labels) do
    text =
      labels
      |> Enum.map(fn {k, v} -> "#{k}=\"#{v}\"" end)
      |> Enum.join(",")
    
    (text == "") && "" || "{#{text}}"
  end
end

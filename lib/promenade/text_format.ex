
defmodule Promenade.TextFormat do
  
  def snapshot(%Promenade.Registry.State{} = state) do
    section(:gauge, state.gauges) <> "\n" <>
    section(:counter, state.counters)
  end
  
  def section(type, metrics) do
    metrics
    |> Enum.map(&(metric(type, elem(&1, 0), elem(&1, 1))))
    |> Enum.join("\n")
  end
  
  def metric(type, name, entries) do
    "# TYPE #{name} #{type}\n" <> (
      entries
      |> Enum.map(&(entry(name, elem(&1, 0), elem(&1, 1))))
      |> Enum.join
    )
  end
  
  def entry(name, labels, value) do
    "#{name}#{labels_text(labels)} #{value}\n"
  end
  
  def labels_text(labels) do
    text = labels
           |> Enum.map(&("#{elem(&1, 0)}=\"#{elem(&1, 1)}\""))
           |> Enum.join(",")
    
    (text == "") && "" || "{#{text}}"
  end
end

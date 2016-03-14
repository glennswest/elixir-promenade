
defmodule Promenade.Decode do
  
  def packet(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&(line(&1)))
  end
  
  def line(input) do
    try do
      {input, suffix} = input |> String.split_at(-2)
      [name, value]   = input |> String.split(":", parts: 2)
      
      suffix =
        case suffix do
          "|g" -> :gauge
          "|c" -> :counter
          _    -> :unknown_suffix = suffix
        end
      
      {value, ""} = value |> Float.parse
      
      {name, labels} =
        case name |> String.split("{", parts: 2) do
          [^name] -> {name, %{}}
          [name, rest] ->
            {rest, "}"} = rest |> String.rstrip |> String.split_at(-1)
            {name, labels(rest)}
        end
      
      {suffix, name, value, labels}
    rescue e ->
      e |> Promenade.Util.reraise_prefixed("Error parsing line: #{input}")
    end
  end
  
  @label_pattern ~r/(\s*)\w+(\s*=\s*")(?:[^"\\]|\\.)*("\s*,?\s*)/
  @label_split_opts [parts: 3, on: [1, 2, 3]]
  
  def labels(input, labels \\ %{})
  def labels("", labels), do: labels
  def labels(input, labels) do
    [key, val, rest] = Regex.split(@label_pattern, input, @label_split_opts)
    
    labels(rest, labels |> Map.put(key, val))
  end
end

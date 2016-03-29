
defmodule Promenade.Decode do
  require Logger
  
  def packet(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&(line(&1)))
    |> Enum.filter(&(&1))
  end
  
  @final_colon_pattern ~r/:(?=[^:]*$)/
  
  def line(input) do
    try do
      {input, suffix} = input |> String.split_at(-2)
      [name, value]   = input |> String.split(@final_colon_pattern, parts: 2)
      
      suffix =
        case suffix do
          "|g" -> :gauge
          "|c" -> :counter
          "|s" -> :summary
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
      Logger.warn "Couldn't decode line: #{input}"
      Logger.warn Exception.format(:error, e, System.stacktrace)
      nil
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


defmodule Promenade.Registry do
  use ExActor.GenServer
  require Logger
  
  alias Promenade.Summary
  
  def start_link(name, io_modules) do
    GenServer.start_link(__MODULE__, io_modules, name: name)
  end
  
  def init(io_modules) do
    tables = {
      :ets.new(:gauges,    []),
      :ets.new(:counters,  []),
      :ets.new(:summaries, []),
    }
    
    Promenade.IoSupervisor.start_link(Promenade.IoSupervisor,
      registry: self(),
      tables:   tables,
      modules:  io_modules,
    )
    
    initial_state tables
  end
  
  def data({gauges, counters, summaries}) do
    {
      gauges    |> :ets.tab2list,
      counters  |> :ets.tab2list,
      summaries |> :ets.tab2list,
    }
  end
  
  defp clear({gauges, counters, summaries}) do
    gauges    |> :ets.delete_all_objects
    counters  |> :ets.delete_all_objects
    summaries |> :ets.delete_all_objects
  end
  
  defcall get_tables, state: state, do: reply state
  
  defcall flush_data, state: state do
    data = data(state)
    clear(state)
    reply data
  end
  
  defcast handle_metrics(metrics), state: state do
    new_state handle_metrics_(state, metrics)
  end
  
  defp handle_metrics_(state, []), do: state
  defp handle_metrics_(state, [first | rest]) do
    state |> handle_metric(first) |> handle_metrics_(rest)
  end
  
  defp handle_metric(state = {table, _, _}, {:gauge, name, value, labels}) do
    unless table |> :ets.insert_new({name, %{} |> Map.put(labels, value)}) do
      map = table
            |> :ets.lookup_element(name, 2)
            |> Map.put(labels, value)
      table |> :ets.insert({name, map})
    end
    
    state
  end
  
  defp handle_metric(state = {_, table, _}, {:counter, name, value, labels}) do
    unless table |> :ets.insert_new({name, %{} |> Map.put(labels, value)}) do
      map = table
            |> :ets.lookup_element(name, 2)
            |> Map.update(labels, value, &(&1 + value))
      table |> :ets.insert({name, map})
    end
    
    state
  end
  
  defp handle_metric(state = {_, _, table}, {:summary, name, value, labels}) do
    unless table |> :ets.insert_new({name, %{} |> Map.put(labels, Summary.new(value))}) do
      map = table
            |> :ets.lookup_element(name, 2)
            |> Map.update(labels, Summary.new(value), &(Summary.observe(&1, value)))
      table |> :ets.insert({name, map})
    end
    
    state
  end
end


defmodule Promenade.Registry do
  use ExActor.GenServer
  require Logger
  
  defmodule State do
    defstruct \
      gauges: %{},
      counters: %{},
      histograms: %{}
  end
  
  def start_link(name, io_modules) do
    GenServer.start_link(__MODULE__, io_modules, name: name)
  end
  
  def init(io_modules) do
    Promenade.IoSupervisor.start_link(Promenade.IoSupervisor,
      registry: self,
      modules: io_modules
    )
    
    initial_state %State{}
  end
  
  defcall get_state, state: state, do: reply state
  
  defcast handle_metrics(metrics), state: state do
    new_state handle_metrics_(state, metrics)
  end
  
  defp handle_metrics_(state, []), do: state
  defp handle_metrics_(state, [first | rest]) do
    state |> handle_metric(first) |> handle_metrics_(rest)
  end
  
  defp handle_metric(state, {:gauge, name, value, labels}) do
    %State { state | gauges: state.gauges
      |> Map.update(name, %{ labels => value }, fn(inner) -> inner
        |> Map.put(labels, value)
      end)
    }
  end
  
  defp handle_metric(state, {:counter, name, value, labels}) do
    %State { state | counters: state.counters
      |> Map.update(name, %{ labels => value }, fn(inner) -> inner
        |> Map.update(labels, value, &(&1 + value))
      end)
    }
  end
end

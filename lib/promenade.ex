
defmodule Promenade do
  use Application
  
  def start(_type, _opts) do
    Process.register(self(), __MODULE__)
    
    {:ok, _pid} = Promenade.Registry.start_link(Promenade.Registry, [
      Promenade.UdpListener,
      Promenade.HttpServer,
    ])
  end
  
  @doc """
  Current total erlang memory usage, in megabytes.
  """
  def memory, do: :erlang.memory(:total) / 1_000_000
  
  @doc """
  Return true if total erlang memory is over the configured high water mark.
  """
  def memory_over_hwm? do
    case Application.fetch_env!(:promenade, :memory_hwm) do
      0   -> false
      hwm -> memory() >= hwm
    end
  end
end

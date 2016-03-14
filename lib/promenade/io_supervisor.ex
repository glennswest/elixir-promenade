
defmodule Promenade.IoSupervisor do
  use Supervisor
  
  def start_link(name, opts) do
    Supervisor.start_link(__MODULE__, opts, name: name)
  end
  
  def init(opts) do
    registry = opts |> Keyword.fetch!(:registry)
    modules  = opts |> Keyword.fetch!(:modules)
    
    modules
    |> Enum.map(&(worker(&1, [&1, registry])))
    |> supervise(strategy: :one_for_one)
  end
end

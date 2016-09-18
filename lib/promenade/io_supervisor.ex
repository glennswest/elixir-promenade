
defmodule Promenade.IoSupervisor do
  use Supervisor
  
  def start_link(name, opts) do
    Supervisor.start_link(__MODULE__, opts, name: name)
  end
  
  def init(opts) do
    {modules, opts} = opts |> Keyword.pop(:modules)
    
    modules
    |> Enum.map(&(worker(&1, [&1, opts])))
    |> supervise(strategy: :one_for_one)
  end
end

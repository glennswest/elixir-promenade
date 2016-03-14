
defmodule Promenade do
  use Application
  
  def start(_type, _opts) do
    Process.register(self, __MODULE__)
    
    {:ok, _pid} = Promenade.Registry.start_link(Promenade.Registry, [
      Promenade.UdpListener,
      Promenade.HttpServer,
    ])
  end
end

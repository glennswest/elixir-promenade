
defmodule Promenade.UdpListener do
  require Logger
  
  def port,        do: Application.fetch_env!(:promenade, :udp_port)
  def inet_opts,   do: [:binary, active: false]
  def make_socket, do: ({:ok, s} = :gen_udp.open(port, inet_opts); s)
  
  def start_link(a, b), do: Task.start_link fn -> run(a, b) end
  
  def run(name, opts) do
    registry = opts |> Keyword.fetch!(:registry)
    
    Process.register(self, name)
    Logger.info("#{inspect name} listening for UDP input on port #{port}")
    
    handle_packets(registry, make_socket)
  end
  
  def handle_packets(registry, socket) do
    handle_packet(registry, socket)
    handle_packets(registry, socket)
  end
  
  def handle_packet(registry, socket) do
    {:ok, {_, _, packet}} = socket |> :gen_udp.recv(0)
    
    metrics = Promenade.Decode.packet(packet)
    
    registry |> Promenade.Registry.handle_metrics(metrics)  
  end
end

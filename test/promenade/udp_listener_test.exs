
defmodule Promenade.UdpListenerTest do
  use ExUnit.Case
  doctest Promenade.UdpListener
  
  defmodule MockGenServer do
    use ExActor.GenServer
    
    defstart start_link, do: initial_state({nil, nil})
    
    defcall get_last_cast, state: {last_cast, _}, do: reply(last_cast)
    defcall get_last_call, state: {_, last_call}, do: reply(last_call)
    
    def handle_call(m, _, {last_cast, _}), do: {:noreply, {last_cast, m}}
    def handle_cast(m, {_, last_call}), do: {:noreply, {m, last_call}}
  end
  
  def udp_send(data, port, host \\ 'localhost') do
    {:ok, sender} = :gen_udp.open(0, [:binary, active: false])
    
    :ok = :gen_udp.send(sender, host, port, data)
  end
  
  def make_udp_socket(port \\ 0) do
    {:ok, socket} = :gen_udp.open(port, [:binary, active: false])
    
    socket
  end
  
  test "handle_packet reads a UDP datagram and forwards it to the registry" do
    data   = "foo:99|g\nbar{label1=\"xxx\",label2=\"yyy\"}:5|c\n"
    socket = make_udp_socket
    {:ok, port} = :inet.port(socket)
    
    udp_send(data, port)
    
    {:ok, mock} = MockGenServer.start_link
    
    Promenade.UdpListener.handle_packet(mock, socket)
    
    expected = {:handle_metrics, Promenade.Decode.packet(data)}
    
    assert MockGenServer.get_last_cast(mock) == expected
  end
end

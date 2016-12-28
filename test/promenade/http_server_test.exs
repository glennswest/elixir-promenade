
defmodule Promenade.HttpServerTest do
  use ExUnit.Case, async: true
  use Plug.Test
  
  alias Promenade.HttpServer
  alias Promenade.Registry
  alias Promenade.TextFormat
  
  def registry do
    {:error, {:already_started, pid}} = Registry.start_link(Registry, [])
    
    pid
  end
  
  def tables, do: registry |> Registry.get_tables
  
  def call(method, path) do
    conn(method, path)
    |> HttpServer.call(registry: registry, tables: tables)
  end
  
  test "/status" do
    conn = call(:get, "/status")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == ""
  end
  
  test "/metrics" do
    registry |> Registry.handle_metrics [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
    ]
    
    expected_body = tables |> Registry.data |> TextFormat.snapshot
    
    conn = call(:get, "/metrics")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
  end
end

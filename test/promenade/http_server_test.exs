
defmodule Promenade.HttpServerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  
  alias Promenade.HttpServer
  alias Promenade.Registry
  alias Promenade.TextFormat
  
  def registry do
    {:error, {:already_started, pid}} = Registry.start_link(Registry, [])
    
    pid
  end
  
  def tables, do: registry() |> Registry.get_tables
  
  def call(method, path) do
    conn(method, path)
    |> HttpServer.call(registry: registry(), tables: tables())
  end
  
  test "/status" do
    conn = call(:get, "/status")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == ""
  end
  
  test "/metrics (no flush - metrics are retained between scrapes)" do
    Registry.handle_metrics registry(), [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
    ]
    
    expected_body = tables() |> Registry.data |> TextFormat.snapshot
    
    conn = call(:get, "/metrics")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
    
    conn = call(:get, "/metrics")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
  end
  
  test "/metrics (flush due to memory high water mark)" do
    Registry.handle_metrics registry(), [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
    ]
    
    expected_body = tables() |> Registry.data |> TextFormat.snapshot
    
    # Set a very low high water mark that we are surely already above,
    # which will ensure a flush on the next metrics scrape.
    Application.put_env(:promenade, :memory_hwm, Promenade.memory / 10)
    assert Promenade.memory_over_hwm?
    
    conn = call(:get, "/metrics")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == expected_body
    
    # Reset high water mark.
    Application.put_env(:promenade, :memory_hwm, 0)
    assert !Promenade.memory_over_hwm?
    
    conn = call(:get, "/metrics")
    
    assert conn.state     == :sent
    assert conn.status    == 200
    assert conn.resp_body == TextFormat.snapshot({[], [], []})
  end
end

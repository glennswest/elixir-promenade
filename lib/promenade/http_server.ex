
defmodule Promenade.HttpServer do
  require Logger
  import Plug.Conn
  
  def port, do: Application.fetch_env!(:promenade, :http_port)
  def start_link(name, registry) do
    # TODO: make this actually linked
    Logger.info("#{inspect name} serving HTTP requests on port #{port}")
    
    Plug.Adapters.Cowboy.http(__MODULE__, [registry: registry], port: port)
  end
  
  def init(opts) do
    opts |> Keyword.fetch!(:registry)
    
    opts
  end
  
  def call(conn, opts) do
    text =
      opts
      |> Keyword.fetch!(:registry)
      |> Promenade.Registry.get_state
      |> Promenade.TextFormat.snapshot
    
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, text)
  end
end

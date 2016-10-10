
defmodule Promenade.HttpServer do
  require Logger
  import Plug.Conn
  
  def port, do: Application.fetch_env!(:promenade, :http_port)
  def start_link(name, opts) do
    # TODO: make this actually linked
    Logger.info("#{inspect name} serving HTTP requests on port #{port}")
    
    Plug.Adapters.Cowboy.http(__MODULE__, opts, port: port)
  end
  
  def init(opts) do
    opts
  end
  
  def call(conn, opts) do
    text =
      opts
      |> Keyword.fetch!(:tables)
      |> Promenade.Registry.data
      |> Promenade.TextFormat.snapshot
    
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, text)
  end
end

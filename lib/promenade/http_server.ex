
defmodule Promenade.HttpServer do
  require Logger
  import Plug.Conn
  
  alias Promenade.Registry
  alias Promenade.TextFormat
  
  def port, do: Application.fetch_env!(:promenade, :http_port)
  def start_link(name, opts) do
    # TODO: make this actually linked
    Logger.info("#{inspect name} serving HTTP requests on port #{port}")
    
    Plug.Adapters.Cowboy.http(__MODULE__, opts, port: port)
  end
  
  def init(opts), do: opts
  
  def call(conn = %Plug.Conn { path_info: ["status"] }, opts) do
    conn |> respond(200, "")
  end
  
  def call(conn, opts) do
    text =
      opts
      |> Keyword.fetch!(:tables)
      |> Registry.data
      |> TextFormat.snapshot
    
    conn |> respond(200, text)
  end
  
  defp respond(conn, code, body) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(code, body)
  end
end

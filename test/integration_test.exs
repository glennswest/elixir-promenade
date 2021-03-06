
defmodule IntegrationTest do
  use ExUnit.Case
  require Logger
  
  @moduletag external: true
  @moduletag timeout: :infinity
  
  defp cmd(name, args, opts \\ []) do
    {allow_fail, opts} = opts |> Keyword.pop(:allow_fail)
    
    {io, code} = System.cmd(name, args, opts)
    
    unless allow_fail do
      {:exit_code, 0} = {:exit_code, code}
    end
    
    io
  end
  
  defp random_id(bytesize \\ 10) do
    :crypto.strong_rand_bytes(bytesize) |> Base.hex_encode32
  end
  
  defp udp_send(data, port, host) do
    {:ok, sender} = :gen_udp.open(0, [:binary, active: false])
    
    :ok = :gen_udp.send(sender, host, port, data)
  end
  
  defp get_docker_ip(id) do
    [_, ip] =
      Regex.run ~r/^'([^']*)'/,
        cmd("docker", ~w(inspect -f '{{.NetworkSettings.IPAddress}}' #{id}))
    ip
  end
  
  defp curl_metrics(ip) do
    cmd("curl", ["--silent", "http://#{ip}:8080/metrics"])
    |> String.strip
    |> String.split("\n")
  end
  
  defp send_metrics(list, ip) do
    list
    |> Enum.join("\n")
    |> udp_send(8126, ip |> to_char_list)
  end
  
  test "builds and runs as a docker container" do
    c_id  = random_id()
    stdio = IO.stream(:stdio, :line)
    
    # cmd "make", ~w(release image=local/test-promenade), into: stdio
    
    Task.start_link fn ->
      cmd "docker", ~w(run --name #{c_id} local/test-promenade),
        into: stdio, allow_fail: true
    end
    
    :timer.sleep(5_000) # wait for container to start
    
    c_ip = get_docker_ip(c_id)
    
    Logger.info("sending some invalid metrics over UDP - should not crash")
    [
      "nope",
      "nope:88|ms",
    ]
    |> send_metrics(c_ip)
    
    :timer.sleep(1_000) # wait for service to process the metrics
    
    Logger.info("sending some seed metrics over UDP")
    [
      "foo:88|g",
      "bar:99|c",
      "baz:1.1|s",
    ]
    |> send_metrics(c_ip)
    
    :timer.sleep(1_000) # wait for service to process the metrics
    
    Logger.info("fetching result metrics from HTTP")
    body = (curl_metrics(c_ip) |> Enum.join("\n")) <> "\n"
    assert body =~
      """
      # TYPE foo gauge
      foo 88.0
      """
    
    assert body =~
      """
      # TYPE bar counter
      bar 99.0
      """
    
    assert body =~
      """
      # TYPE baz summary
      baz{quantile=\"0.5\"} 1.1
      baz{quantile=\"0.9\"} 1.1
      baz{quantile=\"0.99\"} 1.1
      baz_sum 1.1
      baz_count 1
      """
    
    cmd "docker", ~w(rm -f #{c_id})
  end
end

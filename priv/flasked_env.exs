%{
  promenade: %{
    http_port: {:flasked, :PROMENADE_HTTP_PORT, :integer, 8080},
    udp_port:  {:flasked, :PROMENADE_UDP_PORT,  :integer, 8126},
  }
}

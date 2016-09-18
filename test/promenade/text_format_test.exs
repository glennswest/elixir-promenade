
defmodule Promenade.TextFormatTest do
  use ExUnit.Case
  doctest Promenade.Registry
  
  test "prints formatted metrics from table data" do
    data = {
      [
        {"foo", %{
          %{ "x" => "XXX" } => 77.7,
          %{ "y" => "YYY" } => 44.4,
        }},
        {"foo2", %{
          %{ "x" => "XXX", "y" => "YYY" } => 33.3
        }},
      ],
      [
        {"bar", %{
          %{ "x" => "XXX" } => 222,
          %{ "y" => "YYY" } => 33,
        }},
        {"bar2", %{
          %{ "x" => "XXX", "y" => "YYY" } => 111
        }},
      ],
      [
        {"baz", %{
          %{ "x" => "XXX" } => Promenade.Summary.new(5.5),
          %{ "y" => "YYY" } => Promenade.Summary.new(6.6),
        }},
        {"baz2", %{
          %{ "x" => "XXX", "y" => "YYY" } => Promenade.Summary.new(3.3),
        }},
      ],
    }
    
    assert Promenade.TextFormat.snapshot(data) ==
"""
# TYPE foo gauge
foo{x="XXX"} 77.7
foo{y="YYY"} 44.4

# TYPE foo2 gauge
foo2{x="XXX",y="YYY"} 33.3

# TYPE bar counter
bar{x="XXX"} 222
bar{y="YYY"} 33

# TYPE bar2 counter
bar2{x="XXX",y="YYY"} 111

# TYPE baz summary
baz{quantile="0.5",x="XXX"} 5.5
baz{quantile="0.9",x="XXX"} 5.5
baz{quantile="0.99",x="XXX"} 5.5
baz_sum{x="XXX"} 5.5
baz_count{x="XXX"} 1
baz{quantile="0.5",y="YYY"} 6.6
baz{quantile="0.9",y="YYY"} 6.6
baz{quantile="0.99",y="YYY"} 6.6
baz_sum{y="YYY"} 6.6
baz_count{y="YYY"} 1

# TYPE baz2 summary
baz2{quantile="0.5",x="XXX",y="YYY"} 3.3
baz2{quantile="0.9",x="XXX",y="YYY"} 3.3
baz2{quantile="0.99",x="XXX",y="YYY"} 3.3
baz2_sum{x="XXX",y="YYY"} 3.3
baz2_count{x="XXX",y="YYY"} 1
"""
  end
end


defmodule Promenade.TextFormatTest do
  use ExUnit.Case
  doctest Promenade.Registry
  
  test "accumulates metrics into its state" do
    state = %Promenade.Registry.State {
      gauges: %{
        "foo" => %{
          %{ "x" => "XXX" } => 77.7,
          %{ "y" => "YYY" } => 44.4,
        },
        "foo2" => %{
          %{ "x" => "XXX", "y" => "YYY" } => 33.3
        },
      },
      counters: %{
        "bar" => %{
          %{ "x" => "XXX" } => 222,
          %{ "y" => "YYY" } => 33,
        },
        "bar2" => %{
          %{ "x" => "XXX", "y" => "YYY" } => 111
        },
      },
    }
    
    assert Promenade.TextFormat.snapshot(state) ==
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
"""
  end
end

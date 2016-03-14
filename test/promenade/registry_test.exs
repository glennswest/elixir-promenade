
defmodule Promenade.RegistryTest do
  use ExUnit.Case
  doctest Promenade.Registry
  
  def make_subject, do: ({:ok, s} = Promenade.Registry.start_link(nil, []); s)
  
  test "accumulates metrics into its state" do
    subject = make_subject
    
    Promenade.Registry.handle_metrics subject, [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
      {:gauge, "foo", 44.4, %{ "y" => "YYY" }},
      {:gauge, "foo2", 22.2, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 99, %{ "x" => "XXX" }},
      {:counter, "bar", 33, %{ "y" => "YYY" }},
      {:counter, "bar2", 11, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    assert Promenade.Registry.get_state(subject) == %Promenade.Registry.State {
      gauges: %{
        "foo" => %{
          %{ "x" => "XXX" } => 88.8,
          %{ "y" => "YYY" } => 44.4,
        },
        "foo2" => %{
          %{ "x" => "XXX", "y" => "YYY" } => 22.2
        },
      },
      counters: %{
        "bar" => %{
          %{ "x" => "XXX" } => 99,
          %{ "y" => "YYY" } => 33,
        },
        "bar2" => %{
          %{ "x" => "XXX", "y" => "YYY" } => 11
        },
      },
    }
    
    Promenade.Registry.handle_metrics subject, [
      {:gauge, "foo", 77.7, %{ "x" => "XXX" }},
      {:gauge, "foo2", 33.3, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 123, %{ "x" => "XXX" }},
      {:counter, "bar2", 100, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    assert Promenade.Registry.get_state(subject) == %Promenade.Registry.State {
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
  end
end

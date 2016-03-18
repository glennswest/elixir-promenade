
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
      {:summary, "baz", 5.5, %{ "x" => "XXX" }},
    ]
    
    assert Promenade.Registry.get_state(subject).gauges == %{
      "foo" => %{
        %{ "x" => "XXX" } => 88.8,
        %{ "y" => "YYY" } => 44.4,
      },
      "foo2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 22.2
      },
    }
    
    assert Promenade.Registry.get_state(subject).counters == %{
      "bar" => %{
        %{ "x" => "XXX" } => 99,
        %{ "y" => "YYY" } => 33,
      },
      "bar2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 11
      },
    }
    
    summary =
      Promenade.Registry.get_state(subject).summaries
      |> Map.get("baz")
      |> Map.get(%{ "x" => "XXX" })
    
    assert Promenade.Summary.count(summary)          == 1
    assert Promenade.Summary.sum(summary)            == 5.5
    assert Promenade.Summary.quantile(summary, 0.5)  == 5.5
    assert Promenade.Summary.quantile(summary, 0.9)  == 5.5
    assert Promenade.Summary.quantile(summary, 0.99) == 5.5
    
    Promenade.Registry.handle_metrics subject, [
      {:gauge, "foo", 77.7, %{ "x" => "XXX" }},
      {:gauge, "foo2", 33.3, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 123, %{ "x" => "XXX" }},
      {:counter, "bar2", 100, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    assert Promenade.Registry.get_state(subject).gauges == %{
      "foo" => %{
        %{ "x" => "XXX" } => 77.7,
        %{ "y" => "YYY" } => 44.4,
      },
      "foo2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 33.3
      },
    }
    
    assert Promenade.Registry.get_state(subject).counters == %{
      "bar" => %{
        %{ "x" => "XXX" } => 222,
        %{ "y" => "YYY" } => 33,
      },
      "bar2" => %{
        %{ "x" => "XXX", "y" => "YYY" } => 111
      },
    }
    
    Promenade.Registry.handle_metrics subject, [
      {:summary, "baz", 1.1,  %{ "x" => "XXX" }},
      {:summary, "baz", 2.2,  %{ "x" => "XXX" }},
      {:summary, "baz", 3.3,  %{ "x" => "XXX" }},
      {:summary, "baz", 10.1, %{ "x" => "XXX" }},
      {:summary, "baz", 100,  %{ "x" => "XXX" }},
      {:summary, "baz", 88.8, %{ "x" => "XXX" }},
      {:summary, "baz", 43.5, %{ "x" => "XXX" }},
      {:summary, "baz", 45.5, %{ "x" => "XXX" }},
      {:summary, "baz", 33.3, %{ "x" => "XXX" }},
    ]
    
    summary =
      Promenade.Registry.get_state(subject).summaries
      |> Map.get("baz")
      |> Map.get(%{ "x" => "XXX" })
    
    assert Promenade.Summary.count(summary)          == 10
    assert Promenade.Summary.sum(summary)            == 333.3
    assert Promenade.Summary.quantile(summary, 0.5)  == 33.3
    assert Promenade.Summary.quantile(summary, 0.9)  == 100
    assert Promenade.Summary.quantile(summary, 0.99) == 100
  end
end

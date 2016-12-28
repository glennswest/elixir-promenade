
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
    
    {gauges, counters, summaries} =
      subject |> Promenade.Registry.get_tables |> Promenade.Registry.data
    
    assert Enum.sort(gauges) == [
      {"foo", %{
        %{ "x" => "XXX" } => 88.8,
        %{ "y" => "YYY" } => 44.4,
      }},
      {"foo2", %{
        %{ "x" => "XXX", "y" => "YYY" } => 22.2
      }},
    ]
    
    assert Enum.sort(counters) == [
      {"bar", %{
        %{ "x" => "XXX" } => 99,
        %{ "y" => "YYY" } => 33,
      }},
      {"bar2", %{
        %{ "x" => "XXX", "y" => "YYY" } => 11
      }},
    ]
    
    summary = Map.new(summaries) |> Map.get("baz") |> Map.get(%{ "x" => "XXX" })
    
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
    
    {gauges, counters, _summaries} =
      subject |> Promenade.Registry.get_tables |> Promenade.Registry.data
    
    assert Enum.sort(gauges) == [
      {"foo", %{
        %{ "x" => "XXX" } => 77.7,
        %{ "y" => "YYY" } => 44.4,
      }},
      {"foo2", %{
        %{ "x" => "XXX", "y" => "YYY" } => 33.3
      }},
    ]
    
    assert Enum.sort(counters) == [
      {"bar", %{
        %{ "x" => "XXX" } => 222,
        %{ "y" => "YYY" } => 33,
      }},
      {"bar2", %{
        %{ "x" => "XXX", "y" => "YYY" } => 111
      }},
    ]
    
    for name <- ["baz1", "baz2"] do
      for labels <- [%{ "x" => "XXX" }, %{ "y" => "YYY" }] do
        Promenade.Registry.handle_metrics subject, [
          {:summary, name, 5.5,  labels},
          {:summary, name, 1.1,  labels},
          {:summary, name, 2.2,  labels},
          {:summary, name, 3.3,  labels},
          {:summary, name, 10.1, labels},
          {:summary, name, 100,  labels},
          {:summary, name, 88.8, labels},
          {:summary, name, 43.5, labels},
          {:summary, name, 45.5, labels},
          {:summary, name, 33.3, labels},
        ]
        
        {_gauges, _counters, summaries} =
          subject |> Promenade.Registry.get_tables |> Promenade.Registry.data
        
        summary = Map.new(summaries) |> Map.get(name) |> Map.get(labels)
        
        assert Promenade.Summary.count(summary)          == 10
        assert Promenade.Summary.sum(summary)            == 333.3
        assert Promenade.Summary.quantile(summary, 0.5)  == 33.3
        assert Promenade.Summary.quantile(summary, 0.9)  == 100
        assert Promenade.Summary.quantile(summary, 0.99) == 100
      end
    end
    
    # Flush data from the registry and confirm that it is emptied.
    current_data =
      subject |> Promenade.Registry.get_tables |> Promenade.Registry.data
    
    assert (subject |> Promenade.Registry.flush_data) == current_data
    assert (subject |> Promenade.Registry.flush_data) == {[], [], []}
    
    # Confirm that new metrics can be accumulated after clearing the tables.
    Promenade.Registry.handle_metrics subject, [
      {:gauge, "new_foo", 88.8, %{ "x" => "XXX" }},
      {:gauge, "new_foo", 44.4, %{ "y" => "YYY" }},
      {:gauge, "new_foo2", 22.2, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    {gauges, _counters, _summaries} =
      subject |> Promenade.Registry.get_tables |> Promenade.Registry.data
    
    assert Enum.sort(gauges) == [
      {"new_foo", %{
        %{ "x" => "XXX" } => 88.8,
        %{ "y" => "YYY" } => 44.4,
      }},
      {"new_foo2", %{
        %{ "x" => "XXX", "y" => "YYY" } => 22.2
      }},
    ]
  end
end

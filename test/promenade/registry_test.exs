
defmodule Promenade.RegistryTest do
  use ExUnit.Case
  
  alias Promenade.Registry
  alias Promenade.Summary
  alias Promenade.VmGauges
  
  def make_subject, do: ({:ok, s} = Registry.start_link(nil, []); s)
  
  test "accumulates metrics into its state" do
    subject = make_subject()
    
    Registry.handle_metrics subject, [
      {:gauge, "foo", 88.8, %{ "x" => "XXX" }},
      {:gauge, "foo", 44.4, %{ "y" => "YYY" }},
      {:gauge, "foo2", 22.2, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 99, %{ "x" => "XXX" }},
      {:counter, "bar", 33, %{ "y" => "YYY" }},
      {:counter, "bar2", 11, %{ "x" => "XXX", "y" => "YYY" }},
      {:summary, "baz", 5.5, %{ "x" => "XXX" }},
    ]
    
    {gauges, counters, summaries} =
      subject |> Registry.get_tables |> Registry.data(false)
    
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
    
    assert Summary.count(summary)          == 1
    assert Summary.sum(summary)            == 5.5
    assert Summary.quantile(summary, 0.5)  == 5.5
    assert Summary.quantile(summary, 0.9)  == 5.5
    assert Summary.quantile(summary, 0.99) == 5.5
    
    Registry.handle_metrics subject, [
      {:gauge, "foo", 77.7, %{ "x" => "XXX" }},
      {:gauge, "foo2", 33.3, %{ "x" => "XXX", "y" => "YYY" }},
      {:counter, "bar", 123, %{ "x" => "XXX" }},
      {:counter, "bar2", 100, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    {gauges, counters, _summaries} =
      subject |> Registry.get_tables |> Registry.data(false)
    
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
        Registry.handle_metrics subject, [
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
          subject |> Registry.get_tables |> Registry.data(false)
        
        summary = Map.new(summaries) |> Map.get(name) |> Map.get(labels)
        
        assert Summary.count(summary)          == 10
        assert Summary.sum(summary)            == 333.3
        assert Summary.quantile(summary, 0.5)  == 33.3
        assert Summary.quantile(summary, 0.9)  == 100
        assert Summary.quantile(summary, 0.99) == 100
      end
    end
    
    # Flush data from the registry and confirm that it is emptied.
    current_data = subject |> Registry.get_tables |> Registry.data(false)
    
    assert (subject |> Registry.flush_data(false)) == current_data
    assert (subject |> Registry.flush_data(false)) == {[], [], []}
    
    # Confirm that new metrics can be accumulated after clearing the tables.
    Registry.handle_metrics subject, [
      {:gauge, "new_foo", 88.8, %{ "x" => "XXX" }},
      {:gauge, "new_foo", 44.4, %{ "y" => "YYY" }},
      {:gauge, "new_foo2", 22.2, %{ "x" => "XXX", "y" => "YYY" }},
    ]
    
    {gauges, _counters, _summaries} =
      subject |> Registry.get_tables |> Registry.data(false)
    
    assert Enum.sort(gauges) == [
      {"new_foo", %{
        %{ "x" => "XXX" } => 88.8,
        %{ "y" => "YYY" } => 44.4,
      }},
      {"new_foo2", %{
        %{ "x" => "XXX", "y" => "YYY" } => 22.2
      }},
    ]
    
    # This time, get data with "internal" metrics included.
    {gauges, counters, summaries} =
      subject |> Registry.get_tables |> Registry.data(true)
    
    assert (gauges |> Enum.sort |> Enum.map(&elem(&1, 0))) ==
      ["new_foo", "new_foo2"] ++ (VmGauges.get |> Enum.map(&elem(&1, 0)))
    
    assert counters == [{"promenade_metrics_total", %{ %{} => 3 }}]
    
    assert summaries == []
    
    # Now, flush data with "internal" metrics included.
    {gauges, counters, summaries} =
      subject |> Registry.flush_data(true)
    
    assert (gauges |> Enum.sort |> Enum.map(&elem(&1, 0))) ==
      ["new_foo", "new_foo2"] ++ (VmGauges.get |> Enum.map(&elem(&1, 0)))
    
    assert counters == [{"promenade_metrics_total", %{ %{} => 3 }}]
    
    assert summaries == []
  end
end

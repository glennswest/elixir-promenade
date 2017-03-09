
defmodule Promenade.VmGauges do
  def get, do: [
    {"promenade_vm_active_tasks",       gauge(:scheduler, :active_tasks)},
    {"promenade_vm_context_switches",   gauge(:context_switches)},
    {"promenade_vm_gc_count",           gauge(:garbage_collection, 0)},
    {"promenade_vm_gc_words_reclaimed", gauge(:garbage_collection, 1)},
    {"promenade_vm_io_bytes",           gauge(:io)},
    {"promenade_vm_memory_bytes",       gauge(:memory)},
    {"promenade_vm_reductions",         gauge(:reductions)},
    {"promenade_vm_run_queue_lengths",  gauge(:scheduler, :run_queue_lengths)},
  ]
  
  defp gauge(a1, a2 \\ 0)
  
  defp gauge(:scheduler, name) do
    :erlang.statistics(name)
    |> Enum.with_index(1)
    |> Enum.map(fn {val, idx} -> {%{ "scheduler" => to_string(idx) }, val} end)
    |> Enum.into(%{})
  end
  
  defp gauge(:io, _) do
    {{:input, input}, {:output, output}} = :erlang.statistics(:io)
    %{
      %{"direction" => "input"} => input,
      %{"direction" => "output"} => output,
    }
  end
  
  defp gauge(:memory, _) do
    list = :erlang.memory
    
    processes = list |> Keyword.fetch!(:processes)
    atom      = list |> Keyword.fetch!(:atom)
    binary    = list |> Keyword.fetch!(:binary)
    code      = list |> Keyword.fetch!(:code)
    ets       = list |> Keyword.fetch!(:ets)
    system    = list |> Keyword.fetch!(:system)
    
    %{
      %{"kind" => "processes"}    => processes,
      %{"kind" => "atom"}         => atom,
      %{"kind" => "binary"}       => binary,
      %{"kind" => "code"}         => code,
      %{"kind" => "ets"}          => ets,
      %{"kind" => "other_system"} => system - (atom + binary + code + ets),
    }
  end
  
  defp gauge(other, idx) do
    %{ %{} => :erlang.statistics(other) |> elem(idx) }
  end
end

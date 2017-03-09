
defmodule Promenade.VmGaugesTest do
  use ExUnit.Case
  
  alias Promenade.VmGauges
  
  defp is_pos(n), do: is_integer(n) && (n >= 0)
  
  test "returns a list of gauges exposing Erlang VM statistics" do
    gauges = VmGauges.get
    
    assert is_list gauges
    gauges = gauges |> Enum.into(%{})
    
    assert Map.size(gauges["promenade_vm_active_tasks"]) > 0
    for {labels, value} <- gauges["promenade_vm_active_tasks"] do
      assert Integer.parse(labels["scheduler"]) > 0
      assert value >= 0
    end
    
    assert is_pos gauges["promenade_vm_context_switches"][%{}]
    
    assert is_pos gauges["promenade_vm_gc_count"][%{}]
    assert is_pos gauges["promenade_vm_gc_words_reclaimed"][%{}]
    
    assert is_pos gauges["promenade_vm_io_bytes"][%{"direction" => "input"}]
    assert is_pos gauges["promenade_vm_io_bytes"][%{"direction" => "output"}]
    
    memory_bytes = gauges["promenade_vm_memory_bytes"]
    assert is_pos memory_bytes[%{"kind" => "processes"}]
    assert is_pos memory_bytes[%{"kind" => "atom"}]
    assert is_pos memory_bytes[%{"kind" => "binary"}]
    assert is_pos memory_bytes[%{"kind" => "code"}]
    assert is_pos memory_bytes[%{"kind" => "ets"}]
    assert is_pos memory_bytes[%{"kind" => "other_system"}]
    
    assert is_pos gauges["promenade_vm_reductions"][%{}]
    
    assert Map.size(gauges["promenade_vm_run_queue_lengths"]) > 0
    for {labels, value} <- gauges["promenade_vm_run_queue_lengths"] do
      assert Integer.parse(labels["scheduler"]) > 0
      assert is_pos value
    end
  end
end

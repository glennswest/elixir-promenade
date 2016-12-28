
defmodule PromenadeTest do
  use ExUnit.Case, async: false
  
  test "memory_over_hwm? returns false when there is no memory_hwm" do
    assert Application.fetch_env!(:promenade, :memory_hwm) == 0
    
    assert Promenade.memory_over_hwm? == false
  end
  
  test "memory_over_hwm? returns true when memory_hwm is greater than memory" do
    Application.put_env(:promenade, :memory_hwm, Promenade.memory / 10)
    
    assert Promenade.memory_over_hwm?
    
    Application.put_env(:promenade, :memory_hwm, 0)
  end
  
  test "memory_over_hwm? returns false when memory_hwm is less than memory" do
    Application.put_env(:promenade, :memory_hwm, Promenade.memory * 10)
    
    assert !Promenade.memory_over_hwm?
    
    Application.put_env(:promenade, :memory_hwm, 0)
  end
end

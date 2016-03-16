
defmodule Promenade.DecodeTest do
  use ExUnit.Case
  doctest Promenade.Decode
  
  test "labels parses a single label" do
    assert Promenade.Decode.labels("foo=\"bar\"")
      == %{ "foo" => "bar" }
  end
  
  test "labels parses a label with mixed case, underscores, and numbers" do
    assert Promenade.Decode.labels("FOO_88_foo=\"bar\"")
      == %{ "FOO_88_foo" => "bar" }
  end
  
  test "labels parses a label with escaped quotes in the value" do
    assert Promenade.Decode.labels("foo=\"b\\\"a\\\"r\"")
      == %{ "foo" => "b\\\"a\\\"r" }
  end
  
  test "labels parses a label with escaped backslash at the end of the value" do
    assert Promenade.Decode.labels("foo=\"bar\\\\\"")
      == %{ "foo" => "bar\\\\" }
  end
  
  test "labels parses multiple labels" do
    assert Promenade.Decode.labels("x=\"XXX\",y=\"YYY\"")
      == %{ "x" => "XXX", "y" => "YYY"}
  end
  
  test "labels parses multiple labels with extra whitespace and comma" do
    assert Promenade.Decode.labels("x=\"XXX\"  ,  y=\"YYY\"  ,  ")
      == %{ "x" => "XXX", "y" => "YYY"}
  end
  
  test "line parses a simple gauge line" do
    assert Promenade.Decode.line("foo:88.8|g")
      == {:gauge, "foo", 88.8, %{}}
  end
  
  test "line parses a simple counter line" do
    assert Promenade.Decode.line("bar:99|c")
      == {:counter, "bar", 99, %{}}
  end
  
  test "line parses a simple summary line" do
    assert Promenade.Decode.line("baz:11|s")
      == {:summary, "baz", 11, %{}}
  end
  
  test "line parses a gauge line with labels" do
    assert Promenade.Decode.line("foo{x=\"XXX\",y=\"YYY\"}:88.8|g")
      == {:gauge, "foo", 88.8, %{ "x" => "XXX", "y" => "YYY"}}
  end
  
  test "packet parses some newline-separated lines" do
    assert Promenade.Decode.packet("foo:88.8|g\nbar:99|c\nbaz:11|s\n") == [
      {:gauge, "foo", 88.8, %{}},
      {:counter, "bar", 99, %{}},
      {:summary, "baz", 11, %{}},
    ]
  end
end

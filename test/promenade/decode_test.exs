
defmodule Promenade.DecodeTest do
  use ExUnit.Case
  
  alias Promenade.Decode
  
  test "labels parses a single label" do
    assert Decode.labels("foo=\"bar\"")
      == %{ "foo" => "bar" }
  end
  
  test "labels parses a label with mixed case, underscores, and numbers" do
    assert Decode.labels("FOO_88_foo=\"bar\"")
      == %{ "FOO_88_foo" => "bar" }
  end
  
  test "labels parses a label with escaped quotes in the value" do
    assert Decode.labels("foo=\"b\\\"a\\\"r\"")
      == %{ "foo" => "b\\\"a\\\"r" }
  end
  
  test "labels parses a label with escaped backslash at the end of the value" do
    assert Decode.labels("foo=\"bar\\\\\"")
      == %{ "foo" => "bar\\\\" }
  end
  
  test "labels parses multiple labels" do
    assert Decode.labels("x=\"XXX\",y=\"YYY\"")
      == %{ "x" => "XXX", "y" => "YYY"}
  end
  
  test "labels parses multiple labels with extra whitespace and comma" do
    assert Decode.labels("x=\"XXX\"  ,  y=\"YYY\"  ,  ")
      == %{ "x" => "XXX", "y" => "YYY"}
  end
  
  test "line parses a simple gauge line" do
    assert Decode.line("foo:88.8|g")
      == {:gauge, "foo", 88.8, %{}}
  end
  
  test "line parses a simple counter line" do
    assert Decode.line("bar:99|c")
      == {:counter, "bar", 99, %{}}
  end
  
  test "line parses a simple summary line" do
    assert Decode.line("baz:11|s")
      == {:summary, "baz", 11, %{}}
  end
  
  test "line parses a gauge line with labels" do
    assert Decode.line("foo{x=\"XXX\",y=\"YYY\"}:88.8|g")
      == {:gauge, "foo", 88.8, %{ "x" => "XXX", "y" => "YYY" }}
  end
  
  test "line parses a gauge line with empty label group" do
    assert Decode.line("foo{}:88.8|g")
      == {:gauge, "foo", 88.8, %{}}
  end
  
  test "line parses a line with tricky characters in a label value string" do
    assert Decode.line("foo{trick=\"}{:|\"}:88.8|g")
      == {:gauge, "foo", 88.8, %{ "trick" => "}{:|" }}
  end
  
  test "packet parses some newline-separated lines" do
    assert Decode.packet("foo:88.8|g\nbar:99|c\nbaz:11|s\n") == [
      {:gauge, "foo", 88.8, %{}},
      {:counter, "bar", 99, %{}},
      {:summary, "baz", 11, %{}},
    ]
  end
end

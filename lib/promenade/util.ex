
defmodule Promenade.Util do
  
  def reraise_prefixed(exception, prefix_message) do
    type = exception.__struct__ |> inspect
    message = "#{prefix_message}\n(#{type}) #{Exception.message(exception)}"
    reraise(message, System.stacktrace)
  end
end

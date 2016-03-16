
defmodule Promenade.Summary do
  alias Promenade.Util
  alias Promenade.Summary
  
  defstruct \
    qe:    nil,
    total: 0,
    sum:   0.0
  
  # Target 0.5% accuracy for 5th percentile, 2% for 50th percentile, etc.
  @f_targets     [{0.05, 0.005}, {0.5, 0.02}, {0.95, 0.005}]
  
  # Compress data after every 10th observation.
  @compress_rate 10
  
  def new(labels, value) do
    qe =
      @f_targets
      |> :quantile_estimator.f_targeted
      |> :quantile_estimator.new
    
    %Summary { qe: qe, total: 0, sum: 0.0 }
    |> observe(value)
  end
  
  def new_map(labels, value) do
    %{} |> Map.put(labels, new(labels, value))
  end
  
  def observe(%Summary { qe: qe, total: total, sum: sum }, value) do
    qe = :quantile_estimator.insert(value, qe)
    
    if :quantile_estimator.inserts_since_compression(qe) >= @compress_rate do
      qe = :quantile_estimator.compress(qe)
    end
    
    %Summary { qe: qe, total: total + 1, sum: sum + value }
  end
  
  def quantile(summary, q), do: :quantile_estimator.quantile(q, summary.qe)
  def total(summary),       do: summary.total
  def sum(summary),         do: summary.sum
  
  def present(summary, name, labels, show) do
    show.(name, Map.put(labels, "quantile", "0.5"),  quantile(summary, 0.5))
    show.(name, Map.put(labels, "quantile", "0.9"),  quantile(summary, 0.9))
    show.(name, Map.put(labels, "quantile", "0.99"), quantile(summary, 0.99))
    
    show.("#{name}_sum",   labels, summary.sum)
    show.("#{name}_total", labels, summary.total)
  end
end

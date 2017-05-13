defmodule EctoRanked.Utils do
  def ceiling(x) when x < 0, do: trunc(x)
  def ceiling(x) do
    t = trunc(x)
    if x - t == 0, do: t, else: t + 1
  end
end

defmodule EctoRanked.Utils do
  @moduledoc """
  Provides utilities for `EctoRanked`.
  """

  @doc """
  Returns the first integer greater or equal than the provided value.

  ## Examples

      iex> EctoRanked.Utils.ceiling(2.4)
      3

  """
  @spec ceiling(float) :: integer
  def ceiling(value) when value < 0, do: trunc(value)
  def ceiling(value) do
    truncated = trunc(value)
    if value - truncated == 0, do: truncated, else: truncated + 1
  end
end

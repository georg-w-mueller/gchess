defmodule Gchess.Moves.Csteps do

  require Gchess.Moves.Steps
  alias Gchess.Moves.Steps
  alias Gchess.Tools.Tool

  def up_from(x), do: checked(x, Steps.up(), &(&1 >= 0))
  def down_from(x), do: checked(x, Steps.down(), &(&1 <= 63))

  def right_from(x) do
    rank = div(x, 8)
    checked(x, Steps.right(), &(&1 <= 63 && div(&1, 8) == rank))
  end

  def left_from(x) do
    rank = div(x, 8)
    checked(x, Steps.left(), &(&1 >= 0 && div(&1, 8) == rank))
  end

  def up_right_from(x) do
    file = rem(x, 8)
    checked(x, Steps.up_right(), &(&1 >= 0 && rem(&1, 8) > file))
  end

  def up_left_from(x) do
    file = rem(x, 8)
    checked(x, Steps.up_left(), &(&1 >= 0 && rem(&1, 8) < file))
  end

  def down_right_from(x) do
    file = rem(x, 8)
    checked(x, Steps.down_right(), &(&1 <= 63 && rem(&1, 8) > file))
  end

  def down_left_from(x) do
    file = rem(x, 8)
    checked(x, Steps.down_left(), &(&1 <= 63 && rem(&1, 8) < file))
  end

  def checked(x, l, cfun) do
    l |> Stream.map(&(&1 + x)) |> Enum.take_while( &(cfun.(&1) ))
  end

  def knight_from(x) do
    {f, _r} = Tool.file_rank(x)
    [
      k_up_right(x, f),
      k_up_left(x, f),
      k_right_up(x, f),
      k_right_down(x, f),
      k_down_right(x, f),
      k_down_left(x, f),
      k_left_down(x, f),
      k_left_up(x, f)
    ] |> Enum.filter(&(&1 != []))
  end

  def k_up_right(x, f) do
    res = x - 16 + 1
    if res > 0 && rem(res, 8) > f, do: [res], else: []
  end

  def k_up_left(x, f) do
    res =  x - 16 - 1
    if res > 0 && rem(res, 8) < f, do: [res], else: []
  end

  def k_right_up(x, f) do
    res = x + 2 - 8
    if res > 0 && rem(res, 8) > f, do: [res], else: []
  end
  def k_right_down(x, f) do
    res = x + 2 + 8
    if res <= 63 && rem(res, 8) > f, do: [res], else: []
  end
  def k_down_right(x, f) do
    res = x + 16 + 1
    if res <= 63 && rem(res, 8) > f, do: [res], else: []
  end
  def k_down_left(x, f) do
    res = x + 16 - 1
    if res <= 63 && rem(res, 8) < f, do: [res], else: []
  end
  def k_left_down(x, f) do
    res = x - 2 + 8
    if res <= 63 && rem(res, 8) < f, do: [res], else: []
  end
  def k_left_up(x, f) do
    res = x - 2 - 8
    if res > 0 && rem(res, 8) < f, do: [res], else: []
  end
end

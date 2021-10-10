defmodule Gchess.MinMaxTest do
  use ExUnit.Case
  doctest Gchess

alias Gchess.Boards.Simplet, as: S
alias Gchess.Trees.Simple, as: T
alias Gchess.Boards.Fun
alias Gchess.Moves.Move, as: M

  test "drawn position" do
    bd = S.new('7k/7P/6K1/8/8/8/8/8 w')
    t = T.new(bd)

    assert 0 == T.min_max(t, 2) |> elem(1)
  end

  test "mate in one" do
    bd = S.new('7k/7P/6K1/3Rp3/8/8/8/8 w')
    t = T.new(bd)

    {[m], 999} = T.min_max(t, 1)
    assert %M{chessman: :rook, from: 27, is_white: true, to: 3} == m
  end

  test "mate in one II" do
    bd = S.new('8/5K1k/8/3R4/8/8/8/8 w')
    t = T.new(bd)

    {[m], eval} = T.min_max(t, 1)
    assert 999 == eval
    assert %M{chessman: :rook, from: 27, is_white: true, to: 31} == m
  end

  test "mate in two" do
    bd = S.new('7k/8/8/5K2/8/2R5/8/8 w')
    t = T.new(bd)

    {[m | _], 999} = T.min_max(t, 3)
    assert %M{chessman: :king, from: 29, is_white: true, to: 22} == m
  end

  test "mate in two II" do
    bd = S.new('7k/8/6K1/4q3/3R4/8/8/8 w')
    t = T.new(bd)

    {[m | _], 999} = T.min_max(t, 3)
    assert %M{chessman: :rook, from: 35, is_white: true, to: 3} == m
  end

  # test "best move" do
  #   bd = S.new('7k/1b1r2p1/p6p/1p2qN2/4P3/3Q4/P5PP/1B1R2bK ')
  #   t = T.new(bd)

  #   assert 42 == T.min_max(t, 3)
  # end

end # module

defmodule SimpleTest do
  use ExUnit.Case
  doctest Gchess

  alias Gchess.Boards.Simplet, as: Simple
  require Gchess.Boards.Simplet
  alias Gchess.Tools.Tool

  # test "Basic FEN" do
  #   assert Simple.stpos_fen == Simple.stpos
  #   assert  4 == Simple.stpos |> Simple.kingpos_b
  #   assert 60 == Simple.stpos |> Simple.kingpos_w
  # end

  # test "Basic black, white & empty" do
  #   stp = Simple.stpos
  #   bw = 0..63 |> Enum.map(fn n -> {Simple.black?(stp, n), Simple.white?(stp, n), Simple.empty?(stp, n)} end )
  #   assert 0..15  |> Enum.all?( fn n -> bw |> Enum.at(n) == {true, false, false} end)
  #   assert 16..47 |> Enum.all?( fn n -> bw |> Enum.at(n) == {false, false, true} end)
  #   assert 48..63 |> Enum.all?( fn n -> bw |> Enum.at(n) == {false, true, false} end)
  # end

  test "Basic raw" do
    # base, missing pawns at A6 and A2
    bb = Simple.new('rnbqkbnr/1ppppppp/8/8/8/8/1PPPPPPP/RNBQKBNR w KQkq - 0 1', false)
    # down only, hitting white rook (2) at 56 == raw moves from rook at A8
    assert Tool.leql( [8, 16, 24, 32, 40, 48, {56, {:rook, true}}] , Simple.genraw(bb, :rook, 0) )

    bw = Simple.toggle_stp(bb)
    # up only, hitting black rook (8) at 0 ==  raw moves from rook at A1
    assert Tool.leql( [48, 40, 32, 24, 16, 8, {0, {:rook, false}}] , Simple.genraw(bw, :rook, 56) )
  end

end

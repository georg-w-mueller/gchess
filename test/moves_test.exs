defmodule Gchess.MovesTest do
  use ExUnit.Case
  doctest Gchess
  alias Gchess.Moves.Move, as: M

  test "quiet moves" do
    m = M.new_quiet(:pawn, true, 8, 16)
    assert m.is_white
    assert m.from == 8
    assert m.to == 16
    assert m.chessman == :pawn
    assert m.rw_change == 0

    b = M.new_quiet(:rook, false, 8, 16)
    refute b.is_white
    assert b.chessman == :rook
  end

  test "hit moves" do
    m = M.new_hit(:pawn, true, 8, 17, :rook)
    assert 4 == m.rw_change
    assert :rook == Keyword.get(m.options, :hit_piece)

    b = M.new_hit(:pawn, false, 8, 17, :bishop)
    assert -3 == b.rw_change
    assert :bishop == Keyword.get(b.options, :hit_piece)
  end

  test "ep hit moves" do
    m = M.new_ep_hit(true, 27, 20, 28)
    assert 1 == m.rw_change
    assert :pawn == Keyword.get(m.options, :hit_piece)

    b = M.new_ep_hit(false, 36, 43, 35)
    assert -1 == b.rw_change
  end

  test "promotions moves" do
    m = M.new_promotion(true, 8, 0, :rook)
    assert 3 == m.rw_change
    assert :rook == Keyword.get(m.options, :promote_to)

    b = M.new_promotion(false, 55, 63, :queen)
    assert -7 == b.rw_change
    assert :queen == Keyword.get(b.options, :promote_to)
  end

  test "hit promotions moves" do
    m = M.new_hit_promotion(true, 8, 0, :rook, :queen)
    assert 11 == m.rw_change
    assert :queen == Keyword.get(m.options, :promote_to)
    # assert :rook == Keyword.get(m.options, :hit_piece)

    b = M.new_hit_promotion(false, 55, 63, :queen, :queen)
    assert -15 == b.rw_change
    assert :queen == Keyword.get(b.options, :promote_to)
  end

  test "double step" do
    w = M.new_pawn_double(true, 55, 39)
    assert 47 == Keyword.get(w.options, :ep_field)

    b = M.new_pawn_double(false, 8, 24)
    assert 16 == Keyword.get(b.options, :ep_field)
  end

end

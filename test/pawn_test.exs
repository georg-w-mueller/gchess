defmodule Gchess.PawnTest do
  use ExUnit.Case
  doctest Gchess
  alias Gchess.Moves.Pawnmoves, as: P
  alias Gchess.Boards.Simplet, as: S
  alias Gchess.Tools.Tool

  test "enpassant" do
    bw = S.new('4k3/1p6/8/2Pp5/8/8/6P1/4K3 w', true) |> S.set_ep_field(19)
    assert Tool.leql([
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 26,
        is_white: true,
        options: [],
        rw_change: 0,
        to: 18
      },
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 26,
        is_white: true,
        options: [ep_hit: 27, hit_piece: :pawn],
        rw_change: 1,
        to: 19
      }
    ], P.moves_from(bw, 26) )

    bb = S.new('4k3/1p6/8/8/6Pp/8/6P1/4K3 w', false) |> S.set_ep_field(46)
    assert Tool.leql([
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 39,
        is_white: false,
        options: [],
        rw_change: 0,
        to: 47
      },
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 39,
        is_white: false,
        options: [ep_hit: 38, hit_piece: :pawn],
        rw_change: -1,
        to: 46
      }
    ],  P.moves_from(bb, 39) )
  end


  test "straight or hit" do
    bw = S.new('4k3/1p6/8/7p/6P1/8/6P1/4K3 w', true)
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 38,
        is_white: true,
        options: [],
        rw_change: 0,
        to: 30
      },
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 38,
        is_white: true,
        options: [hit_piece: :pawn],
        rw_change: 1,
        to: 31
      }
    ], P.moves_from(bw, 38) )

    bb = S.toggle_stp(bw)
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 31,
        is_white: false,
        options: [],
        rw_change: 0,
        to: 39
      },
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 31,
        is_white: false,
        options: [hit_piece: :pawn],
        rw_change: -1,
        to: 38
      }
    ], P.moves_from(bb, 31) )
  end

  test "basics from base" do
    bw = S.new('4k3/1p6/8/8/8/8/6P1/4K3 w', true)
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 54,
        is_white: true,
        options: [],
        rw_change: 0,
        to: 46
      },
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 54,
        is_white: true,
        options: [ep_field: 46],
        rw_change: 0,
        to: 38
      }
    ], P.moves_from(bw, 54) )

    bb = S.toggle_stp(bw)
    assert Tool.leql([
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 9,
        is_white: false,
        options: [],
        rw_change: 0,
        to: 17
      },
      %Gchess.Moves.Move{
        chessman: :pawn,
        from: 9,
        is_white: false,
        options: [ep_field: 17],
        rw_change: 0,
        to: 25
      }
    ], P.moves_from(bb, 9) )
  end
end

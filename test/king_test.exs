defmodule Gchess.KingTest do
  use ExUnit.Case
  doctest Gchess
  alias Gchess.Moves.Kingmoves, as: K
  alias Gchess.Boards.Simplet, as: S
  alias Gchess.Tools.Tool

  # 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
  test "castling limited by opposite bishop" do
    bd = S.new('r3k2r/3ppp2/1B6/8/8/1b6/3PPP2/R3K2R w KQkq - 0 1') |> S.set_castle('KQkq')

    # black castling short and one step right; castling long & step left are preventend by white bishop
    assert Tool.leql([
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_short: true, castle_kill: 'kq', rook_move: {7, 5}],
        rw_change: 0,
        to: 6
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_kill: 'kq'],
        rw_change: 0,
        to: 5
      }], K.moves_from(bd, 4, false) )

    # white castling short and one step right; castling long & step left are preventend by black bishop
    assert Tool.leql([
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_short: true, castle_kill: 'KQ', rook_move: {63, 61}],
        rw_change: 0,
        to: 62
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_kill: 'KQ'],
        rw_change: 0,
        to: 61
      }], K.moves_from(bd, 60, true) )
  end

  test "castling limited by opposite pawn" do
    bd = S.new('r3k2r/3pppP1/8/8/8/8/3PPPp1/R3K2R w KQkq - 0 1') |> S.set_castle('KQkq')

    # black castling long and one step left; castling short & step right are preventend by white pawn
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_long: true, castle_kill: 'kq', rook_move: {0, 3}],
        rw_change: 0,
        to: 2
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_kill: 'kq'],
        rw_change: 0,
        to: 3
      }] , K.moves_from(bd, 4, false) )

    # white castling long and one step left; castling short & step right are preventend by black pawn
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_long: true, castle_kill: 'KQ', rook_move: {56, 59}],
        rw_change: 0,
        to: 58
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_kill: 'KQ'],
        rw_change: 0,
        to: 59
      }] , K.moves_from(bd, 60, true) )
  end

  test "castling" do
    bd = S.new('r3k2r/3ppp2/8/8/8/8/3PPP2/R3K2R w KQkq - 0 1') |> S.set_castle('KQkq')

    # black castling long and short plus one step left/right
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_long: true, castle_kill: 'kq', rook_move: {0, 3}],
        rw_change: 0,
        to: 2
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_short: true, castle_kill: 'kq', rook_move: {7, 5}],
        rw_change: 0,
        to: 6
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_kill: 'kq'],
        rw_change: 0,
        to: 3
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 4,
        is_white: false,
        options: [castle_kill: 'kq'],
        rw_change: 0,
        to: 5
      }] , K.moves_from(bd, 4, false) )

    # white castling long and short plus one step left/right
    assert Tool.leql( [
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_long: true, castle_kill: 'KQ', rook_move: {56, 59}],
        rw_change: 0,
        to: 58
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_short: true, castle_kill: 'KQ', rook_move: {63, 61}],
        rw_change: 0,
        to: 62
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_kill: 'KQ'],
        rw_change: 0,
        to: 59
      },
      %Gchess.Moves.Move{
        chessman: :king,
        from: 60,
        is_white: true,
        options: [castle_kill: 'KQ'],
        rw_change: 0,
        to: 61
      }
    ] , K.moves_from(bd, 60, true) )
  end

end

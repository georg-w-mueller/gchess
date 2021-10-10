defmodule Gchess.Moves.Kingmoves do
  alias Gchess.Moves.Move
  alias Gchess.Boards.Fun
  alias Gchess.Tools.Tool

  def moves_from(bd, n, white_to_play \\ nil) when n >=0 and n <= 63 do
    {wtp, board} = if white_to_play == nil do
      {Fun.white_to_play?(bd), bd}
    else
      {white_to_play, Fun.set_wtp(bd, white_to_play)}
    end
    # cl = Fun.castle(board)
    # kc = castle_kill(wtp, n, cl)
    bdc = Fun.clear(board, n)
    rm = Fun.genraw_moves(board, :king, n)
      |> Enum.filter(fn m -> not Fun.is_hit?(bdc, m.to, !wtp) end)

    case king_base?(wtp, n) && not (rm |> Enum.empty?()) do
      false -> rm
      true -> add_potcast(board, wtp, Fun.castle(board), rm)
    end
  end

  def add_potcast(_board, _wtp, cops, rm) when is_nil(cops) or cops == [], do: rm

  def add_potcast(board, wtp, cops, rm) do
    tck =  Tool.castle_kill(wtp)
    ashort = if precond_short?(wtp, board, cops) do
      {from, to} = cshort(wtp)
      [ Move.new_king_short(wtp, from, to, rook_short(wtp), tck) | rm ]
    else
      rm
    end
    if precond_long?(wtp, board, cops) do
      {from, to} = clong(wtp)
      [ Move.new_king_long(wtp, from, to, rook_long(wtp), tck) | ashort ]
    else
      ashort
    end
  end

  defp king_base?(true, n), do: n == 60
  defp king_base?(false, n), do: n == 4

  defp rook_short(true), do: {63, 61}
  defp rook_short(false), do: {7, 5}

  defp rook_long(true), do: {56, 59}
  defp rook_long(false), do: {0, 3}

  defp precond_short?(true, board, cops) do
    Tool.castle_short?(true, cops) &&
      Fun.are_empty?(board, [61, 62])
      && not Fun.is_any_hit?(board, [60, 61, 62], false)
  end
  defp precond_short?(false, board, cops) do
    Tool.castle_short?(false, cops) &&
      Fun.are_empty?(board, [5, 6])
      && not Fun.is_any_hit?(board, [4, 5, 6], true)
  end

  defp precond_long?(true, board, cops) do
    Tool.castle_long?(true, cops) &&
      Fun.are_empty?(board, [57, 58, 59])
      && not Fun.is_any_hit?(board, [58, 59, 60], false)
  end
  defp precond_long?(false, board, cops) do
    Tool.castle_long?(false, cops) &&
      Fun.are_empty?(board, [1, 2, 3])
      && not Fun.is_any_hit?(board, [2, 3, 4], true)
  end

  def cshort(true), do: {60, 62}
  def cshort(false), do: {4, 6}

  def clong(true), do: {60, 58}
  def clong(false), do: {4, 2}
end

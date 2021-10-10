defmodule Gchess.Moves.Pawnmoves do
  alias Gchess.Boards.Fun
  alias Gchess.Tools.Tool
  alias Gchess.Moves.Move
  #def get_chm_and_color(target, n)

  def moves_from(board, n, white_to_play \\ nil) when n >=8 and n <= 55 do
    wtp = if white_to_play == nil, do: Fun.white_to_play?(board), else: white_to_play
    fr = Tool.file_rank(n)

    ss = single(wtp, board, n, fr)
    d = if ss == [], do: [], else: double(wtp, board, n, fr)
    bes = beat_east(wtp, board, n, fr)
    bws = beat_west(wtp, board, n, fr)
    ep = enpassant(wtp, board, n, fr)
    [ss, d, bes, bws, ep] |> Enum.flat_map(&(&1))
  end

  def enpassant(wtp, board, n, {_f, r}) do
    if r != enp_rank(wtp) do
      []
    else
      case Fun.ep_field(board) do
        nil -> []
        ephps when is_integer(ephps) ->
          case etp(wtp, n, ephps) do
            true ->
              rm = if wtp, do: ephps + 8, else: ephps - 8
              [ Move.new_ep_hit(wtp, n, ephps, rm) ]
            false -> []
          end
      end
    end
  end

  defp etp(true, n, epos), do: (n - 7 == epos) || (n - 9) == epos
  defp etp(false, n, epos), do: (n + 9 == epos) || (n + 7) == epos

  defp single(wtp, board, n, {_f, r}) do
    pt = n + ahead(wtp)
    # IO.inspect(pt)
    case Fun.get_chm_and_color(board, pt) do
      :empty ->
        # IO.inspect("let's go")
        case r == from_prom_rank(wtp) do
          true -> [
            Move.new_promotion(wtp, n, pt, :queen),
            Move.new_promotion(wtp, n, pt, :rook),
            Move.new_promotion(wtp, n, pt, :bishop),
            Move.new_promotion(wtp, n, pt, :knight)
          ]
          false -> [Move.new_quiet(:pawn, wtp, n, pt)]
        end
      _ -> # IO.inspect("blocked")
         []
    end
  end

  defp double(wtp, board, n, {_f, r}) do
    if r == base_rank(wtp) do
      pt = n + dahead(wtp)
      case Fun.get_chm_and_color(board, pt) do
        {_, _} -> []
        :empty -> [ Move.new_pawn_double(wtp, n, pt) ]
      end
    else
      []
    end
  end

  defp beat_east(wtp, board, n, {f, r}) do
    pt = if wtp, do: n - 7, else: n + 9
    case rem(pt, 8) > f do
      false -> []
      true -> handle_beat(wtp, board, n, r, pt)
    end
  end

  defp beat_west(wtp, board, n, {f, r}) do
    pt = if wtp, do: n - 9, else: n + 7
    # IO.inspect(pt)
    case pt > 0 && rem(pt, 8) < f do
      false -> []
      true -> handle_beat(wtp, board, n, r, pt)
    end
  end

  defp handle_beat(wtp, board, n, r, pt) do
    # IO.inspect(pt)
    case Fun.get_chm_and_color(board, pt) do
      :empty -> []
      {_, ^wtp} -> []
      {x, _} ->
        case r == from_prom_rank(wtp) do
          true -> [
            Move.new_hit_promotion(wtp, n, pt, x, :queen),
            Move.new_hit_promotion(wtp, n, pt, x, :rook),
            Move.new_hit_promotion(wtp, n, pt, x, :bishop),
            Move.new_hit_promotion(wtp, n, pt, x, :knight)
          ]
          false ->  [Move.new_hit(:pawn, wtp, n, pt, x)]
        end
    end
  end

  defp enp_rank(true), do: 3
  defp enp_rank(false), do: 4

  defp base_rank(true), do: 6
  defp base_rank(false), do: 1

  defp from_prom_rank(true), do: 1
  defp from_prom_rank(false), do: 6

  defp ahead(true), do: -8
  defp ahead(false), do: 8

  defp dahead(true), do: -16
  defp dahead(false), do: 16
end

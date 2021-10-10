defmodule Gchess.Moves.Raw do

  require Gchess.Moves.Steps
  require Gchess.Moves.Csteps

  alias Gchess.Moves.Csteps, as: C
  alias Gchess.Tools.Tool, as: T

  for x <- 0..63 do
    straight = [C.up_from(x), C.down_from(x), C.left_from(x), C.right_from(x)] |> Enum.filter(&(&1 != []))
    cross = [C.up_left_from(x), C.down_left_from(x), C.up_right_from(x), C.down_right_from(x)] |> Enum.filter(&(&1 != []))
    base = [
      {:rook, straight},
      {:bishop, cross},
      {:queen, straight ++ cross},
      {:king, (straight |> Enum.map(fn l -> [hd(l)] end)) ++ (cross |> Enum.map(fn l -> [hd(l)] end)) },
      {:knight, C.knight_from(x)}
    ]
    for {f, ms} <- base do
      def raw(unquote(f), unquote(x)), do: unquote(ms)
    end
  end

  for x <- 0..63 do
    pot_white_pawns_attaking = T.hwrp(true, x)
    pot_black_pawns_attaking = T.hwrp(false, x)
    def hwr_pawn(unquote(x), true), do: unquote(pot_white_pawns_attaking)
    def hwr_pawn(unquote(x), false), do: unquote(pot_black_pawns_attaking)
  end

  for x <- 0..63 do
    pot_knight_attacking = C.knight_from(x) |> Enum.flat_map(&(&1))
    def hwr_knight(unquote(x)), do: unquote(pot_knight_attacking)
  end
end

# {:rook, [C.up_from(x), C.down_from(x), C.left_from(x), C.right_from(x)]},
# {:bishop, [C.up_left_from(x), C.down_left_from(x), C.up_right_from(x), C.down_right_from(x)]}

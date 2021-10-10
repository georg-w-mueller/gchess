defmodule Gchess.Tools.Binex do

  for n <- 0..63 do
    def ex(<<hd :: unquote(n*8), _ :: 8, tl :: unquote(8 * (63 - n)) >>, unquote(n), x),
      do: <<hd :: unquote(n*8), x :: 8, tl :: unquote(8 * (63 - n)) >>
  end

# @empty	    0

# @rook_w	    2
# @knight_w   3
# @bishop_w	  4
# @queen_w	  5
# @king_w	    6
# @pawn_w	    7

# @rook_b	    8
# @knight_b   9
# @bishop_b	  10
# @queen_b	  11
# @king_b	    12
# @pawn_b	    13

#  for {w, t} <-
# [ {@empty, :empty},
#   {@rook_w, {:rook, true}},
#   {@knight_w, {:knight, true}},
#   {@bishop_w, {:bishop, true}},
#   {@queen_w, {:queen, true}},
#   {@king_w, {:king, true}},
#   {@pawn_w, {:pawn, true}},
#   {@rook_b, {:rook, false}},
#   {@knight_b, {:knight, false}},
#   {@bishop_b, {:bishop, false}},
#   {@queen_b, {:queen, false}},
#   {@king_b, {:king, false}},
#   {@pawn_b, {:pawn, false}}
# ] do
#   cp = :binary.compile_pattern(<<w::8>>)
#   def cpattern(unquote(t)), do: unquote(cp)
# end

end

alias Gchess.Boards.Simplet, as: S
alias Gchess.Trees.Simple, as: T
alias Gchess.Boards.Fun

# https://www.chessvideos.tv/puzzle-846-VonPopielMarco1902.php
t = T.new(S.new('7k/1b1r2p1/7p/1p2qN2/3bP3/3Q4/6PP/1B1R3K w', false))

# rp = t |> T.mima_prune(6)
# IO.inspect(rp)

rm = t |> T.ab_prune(6)
IO.inspect(rm)

# https://www.chessvideos.tv/puzzle-2652-FromKupreichikTseshkovsky1976.php
# 1r3kr1/2qn1pp1/p2Nb3/6Pp/8/Q4P2/PPP4P/2KRR3

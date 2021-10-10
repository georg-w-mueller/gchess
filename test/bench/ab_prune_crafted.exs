alias Gchess.Boards.Simplet, as: S
alias Gchess.Trees.Simple, as: T

t = T.new(S.new('7k/1b1r2p1/p6p/1p2qN2/3bP3/3Q4/P5PP/1B1R3K ', false))

# @depth 5

Benchee.run(%{
  "enum" => fn -> t |> T.ab_prune(5)  end,
  "crafted" => fn -> t |> T.ab_prune_crafted(5)  end
}, time: 60,  memory_time: 2, parallel: 2) #, parallel: 2

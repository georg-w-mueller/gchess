alias Gchess.Boards.Simplet, as: S
alias Gchess.Trees.Simplee, as: E

t = E.new(S.new('8/6k1/8/8/8/8/1K6/8 '))
te2 = t |> E.expand_to_level(2)

Benchee.run(%{
  "expansion" => fn -> t |> E.expand_to_level(2)  end,
  "re-expanxion" => fn -> te2 |> E.expand_to_level(2)  end
}, time: 60,  memory_time: 2, parallel: 2) #, parallel: 2

alias Gchess.Boards.Simplet, as: S

bd = S.new('1r3kr1/2qn1pp1/p2Nb3/6Pp/1Q6/5P2/PPP4P/2KRR3 ')

n = 1000
nt = fn f -> 1..n |> Stream.map(fn _ -> f.() end) end

Benchee.run(%{
  "par" => fn -> nt.(fn -> bd |> S.gen_moves_p end) |> Stream.run  end,
  "std" => fn -> nt.(fn -> bd |> S.gen_moves end) |> Stream.run  end
}, time: 20,  memory_time: 2) #, parallel: 2

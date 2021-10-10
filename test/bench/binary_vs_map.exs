alias Gchess.Boards.Simple
alias Gchess.Boards.Fun

bd = Simple.new()

base_list = 0..63 |> Enum.map(fn n -> {n, bd |> Fun.get_chm_and_color(n)} end)

mp = base_list
|> Stream.reject(fn {_, fig} -> fig == :empty end)
|> Enum.into(%{})

tp = base_list |> Enum.map(fn {_n, cm} -> cm end) |> :erlang.list_to_tuple()

map_get = fn mp, n when is_map(mp) and n>=0 and n<=63 -> Map.get(mp, n, :empty) end
map_trans = fn mp, from, to when to >= 0 and to <=63 -> Map.put(mp, to, map_get.(mp, from)) |> Map.delete(from) end

tup_get = fn tp, n when is_tuple(tp) and n>=0 and n<=63 -> tp |> elem(n) end  # elem is zero-based!
tup_trans = fn tp, from, to when to >= 0 and to <=63 ->
  :erlang.setelement(from + 1,  # :erlang.setelement is 1-based
    :erlang.setelement(to + 1, tp, tup_get.(tp, from)),
    :empty
  )
end

binboard = bd.board

benchf_bin = fn from, to -> binboard |> Simple.trans(from, to) end
benchf_map = fn from, to -> mp |> map_trans.(from, to) end
benchf_tup = fn from, to -> tp |> tup_trans.(from, to) end

frame = fn bench -> for from <- 0..63, to <- 0..63, do: bench.(from, to) end

Benchee.run(%{
  "bin" => fn -> frame.(benchf_bin) end,
  "map" => fn -> frame.(benchf_map) end,
  "tup" => fn -> frame.(benchf_tup) end
}, time: 20, parallel: 2,  memory_time: 2)

defmodule Gchess.Trees.Simplee do
  alias __MODULE__, as: E

  alias Gchess.Boards.Fun
  alias Gchess.Moves.Move
#  alias Gchess.Trees.Evalresult, as: R
#  alias Gchess.Tools.StatefulMap, as: M

  defstruct history: [], board: nil, trans_list: nil, subnodes: nil, history_len: 0

  def new(board), do: %E{board: board}
  def new(history, board), do: %E{history: history, board: board, history_len: length(history)}
  def new(history, hl, board), do: %E{history: history, board: board, history_len: hl}
  def subnodes(%E{subnodes: sn}), do: sn

  def make_trans(%E{board: board, trans_list: nil} = node) do
    %E{ node | trans_list: board |> Fun.gen_moves() |> Move.sort(Fun.white_to_play?(board)),
              subnodes: [] }
  end
  def make_trans(node), do: node

  def expand(%E{trans_list: []} = node), do: {nil, node}
  def expand(%E{trans_list: nil} = node), do: make_trans(node) |> expand()
  def expand(%E{board: board, trans_list: [hd | rest], subnodes: snds, history: hst, history_len: hl} = node) do
    pnextb = Fun.apply(board, hd)
    next = new([hd | hst], hl+1, pnextb)
    {next,    %E{ node | trans_list: rest, subnodes: [ next | snds] } }
  end

  def max_depth(%E{subnodes: nil}), do: 0
  def max_depth(%E{subnodes: sn}), do: 1 + (sn |> Stream.map(&(max_depth(&1))) |> Enum.max())

  def count(%E{} = t), do: t |> traverse(fn _, acc -> acc + 1 end, 0)

  def count_distinct(%E{} = t), do: t |> stream_nodes |> Stream.uniq_by(fn n -> n.board end) |> Enum.count

  def stream_nodes(%E{} = t), do: t |> traverse(fn n, acc -> Stream.concat(acc, [n]) end, [])

  def expand_to_level(%E{} = t, 0), do: t
  def expand_to_level(%E{subnodes: nil} = t, n), do: t |> make_trans |> expand_to_level(n)
  def expand_to_level(%E{} = t, n) do
    %E{ t | subnodes: t |> exp_sub_stream(n) |> Enum.to_list, trans_list: [] }
  end

  def bottom_left(%E{subnodes: nil} = t), do: t
  def bottom_left(%E{subnodes: []} = t), do: t
  def bottom_left(%E{subnodes: [h | _]}), do: h |> bottom_left

  defp exp_sub_stream(%E{subnodes: sl, trans_list: tl, board: bd, history: h, history_len: hl}, n) do
    sl |> Stream.concat(
    tl |> Stream.map(&E.new([&1 | h], hl + 1, Fun.apply(bd, &1))) )
    |> Stream.map(&expand_to_level(&1, n-1))
  end

  def traverse(%E{subnodes: nil} = t, fun, acc), do: fun.(t, acc)
  def traverse(%E{subnodes: sn} = t, fun, acc) do
    sn |> Enum.reduce(fun.(t, acc), fn s, a -> traverse(s, fun, a) end)
  end

  def traverse_l(t, fun, acc, depth \\ 0)
  def traverse_l(%E{subnodes: nil} = t, fun, acc, depth), do: fun.(t, acc, depth)
  def traverse_l(%E{subnodes: sn} = t, fun, acc, depth) do
    sn |> Enum.reduce(fun.(t, acc, depth), fn s, a -> traverse_l(s, fun, a, depth + 1) end)
  end
end # module

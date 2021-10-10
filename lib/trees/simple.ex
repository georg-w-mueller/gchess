defmodule Gchess.Trees.Simple do
  alias __MODULE__, as: T

  alias Gchess.Boards.Fun
  alias Gchess.Moves.Move
  alias Gchess.Tools.Tool
  alias Gchess.Trees.Evalresult, as: R
  alias Gchess.Tools.StatefulMap, as: M

  defstruct history: [], board: nil, trans_list: nil, subnodes: nil, history_len: 0

  def new(board), do: %T{board: board}
  def new(history, board), do: %T{history: history, board: board, history_len: length(history)}
  def new(history, hl, board), do: %T{history: history, board: board, history_len: hl}
  def subnodes(%T{subnodes: sn}), do: sn

  def make_trans(%T{board: board, trans_list: nil} = node) do
    %T{ node | trans_list: board |> Fun.gen_moves() |> Move.sort(Fun.white_to_play?(board)),
              subnodes: [] }
  end
  def make_trans(node), do: node

  def expand_next(%T{trans_list: []} = node), do: node
  def expand_next(%T{trans_list: nil} = node), do: make_trans(node) |> expand_next()
  def expand_next(%T{board: board, trans_list: [hd | rest], subnodes: snds, history: hst, history_len: hl} = node) do
    pnextb = Fun.apply(board, hd)
    %T{ node | trans_list: rest, subnodes: [ new([hd | hst], hl+1, pnextb) | snds] }
  end

  def expand_all(%T{} = node), do: expand_all_(node, expand_next(node))

  defp expand_all_(node, node), do: node
  defp expand_all_(_nod, node), do: expand_all(node)

  def max_depth(%T{subnodes: nil}), do: 0
  def max_depth(%T{subnodes: sn}), do: 1 + (sn |> Stream.map(&(max_depth(&1))) |> Enum.max())

  def count_nodes(%T{} = t), do: t |> traverse(fn _, acc -> acc + 1 end, 0)

  def stream_nodes(%T{} = t), do: t |> traverse(fn n, acc -> Stream.concat(acc, [n]) end, [])

  def traverse(%T{subnodes: nil} = t, fun, acc), do: fun.(t, acc)
  def traverse(%T{subnodes: sn} = t, fun, acc) do
    sn |> Enum.reduce(fun.(t, acc), fn s, a -> traverse(s, fun, a) end)  #fun.(t, acc)
  end

  def expand_to_level(%T{} = t, 0), do: t
  def expand_to_level(%T{subnodes: nil} = t, n), do: t |> make_trans |> expand_to_level(n)
  def expand_to_level(%T{} = t, n) do
    %T{ t | subnodes: t |> exp_sub_stream(n) |> Enum.to_list, trans_list: [] }
  end

  def bottom_left(%T{subnodes: nil} = t), do: t
  def bottom_left(%T{subnodes: []} = t), do: t
  def bottom_left(%T{subnodes: [h | _]}), do: h |> bottom_left

  defp exp_sub_stream(%T{subnodes: sl, trans_list: tl, board: bd, history: h, history_len: hl}, n) do
    sl |> Stream.concat(
    tl |> Stream.map(&T.new([&1 | h], hl + 1, Fun.apply(bd, &1))) )
    |> Stream.map(&expand_to_level(&1, n-1))
  end

  def gmax({_, value_l} = l, {_, value_r}) when value_l >= value_r, do: l
  def gmax({_, _} =_l, {_, _} = r), do: r
  def gmin({_, value_l} = l, {_, value_r}) when value_l <= value_r, do: l
  def gmin({_, _} =_l, {_, _} = r), do: r

  def min_max(t, n, init_f \\ nil, init_f2 \\ nil)
  def min_max(%T{} = t, 0, _, _), do: t |> eval
  def min_max(%T{board: board} = t, n, nil, nil) do
    case board |> Fun.white_to_play? do
      true  ->  min_max(t, n, {-8888, &gmax/2}, { 8888, &gmin/2}) # init for minmax
      false ->  min_max(t, n, { 8888, &gmin/2}, {-8888, &gmax/2})
    end
  end
  def min_max(%T{} = t, n, {init, f} = ccf, {_, _} = ncf) do
    ea = expand_all(t)
    #IO.inspect(ea)
    case ea.subnodes do
      [] -> # IO.inspect("no child")
        t |> eval   #  => stalemate or checkmate
      cl -> cl
          |> Enum.reduce_while({nil, init}, fn sn, acc ->
            snv = min_max(sn, n - 1, ncf, ccf)
            {_bh, bv} = nacc = f.(snv, acc)
            if abs(bv) > 900, do: {:halt, nacc}, else: {:cont, nacc}
          end)
    end
  end

  def mima(t, n, stop_on_mate \\true, init \\ nil, init2 \\ nil, wtp \\ nil)
  def mima(%T{} = t, _som, 0, _, _, _), do: t |> eval(0)
  def mima(%T{board: board} = t, n, som, nil, nil, nil) do
    wtp = board |> Fun.white_to_play?
    case som do
      true -> mima_som(t, n, R.worst_init(wtp), R.worst_init(not wtp), wtp)
      _ -> mima_(t, n, R.worst_init(wtp), R.worst_init(not wtp), wtp)
    end
  end

  defp mima_(%T{} = t, 0, _, _, _), do: t |> eval(0)
  defp mima_(%T{} = t, n, init, ninit, wtp) do
      r = t |> Enum.reduce(init, fn sn, acc ->
            R.better_from(wtp, mima_(sn, n - 1, ninit, init, not wtp), acc)
          end)
      if r == init, do: t |> eval(n), else: r
  end

  defp mima_som(%T{} = t, 0, _, _, _), do: t |> eval(0)
  defp mima_som(%T{} = t, n, init, ninit, wtp) do
      r = t |> Enum.reduce_while(init, fn sn, acc ->
            best = R.better_from(wtp, mima_som(sn, n - 1, ninit, init, not wtp), acc)
            if R.stop?(best), do: {:halt, best}, else: {:cont, best}
          end)
      if r == init, do: t |> eval(n), else: r
  end

  def ab_prune(%T{board: board} = t, n) do
    wtp = board |> Fun.white_to_play?
    ab_prune_(t, n, R.worst_init(wtp), R.worst_init(not wtp), R.worst_init(true).eval, R.worst_init(false).eval, wtp)
  end

  defp ab_prune_(%T{} = t, 0, _, _, _alpha, _beta, _wtp), do: t |> eval(0)
  defp ab_prune_(%T{} = t, n, init, initb, alpha, beta, wtp) do
    t |> Enum.reduce_while({init, alpha, beta},
    fn sn, {pm, alpha, beta} ->
      rm = ab_prune_(sn, n-1, initb, init, alpha, beta, not wtp)
      bm = R.better_from(wtp, pm, rm)
      {alpha, beta} = if wtp, do: {max(bm.eval, alpha), beta}, else: {alpha, min(bm.eval, beta)}
      if beta <= alpha, do: {:halt, {bm, nil, nil}}, else: {:cont, {bm, alpha, beta}}
    end) |> elem(0) |> case do
      ^init -> t |> eval(n)
      r -> r
    end
  end

  def ab_prune_crafted(%T{} = t, 0), do: t |> eval(0)
  def ab_prune_crafted(%T{board: board} = t, n) do
    wtp = board |> Fun.white_to_play?
    mp = M.new()
    {ab_prune_crafted_(wtp, t, n,
      R.worst_init(wtp), R.worst_init(not wtp),
      R.worst_init(true).eval, R.worst_init(false).eval,
      mp
    ), mp |> M.stop} |> elem(0)
  end

  # defp ab_prune_crafted_(_wtp, %T{} = t, 0, _, _, _alpha, _beta, _mp), do: t |> eval(0)
  defp ab_prune_crafted_(wtp, %T{board: bd, history: h, history_len: hl} = t, n, init, initb, alpha, beta, mp) do
    case mp |> M.get(bd) do
      nil ->
        if n !=0, do: ( case (t |> make_trans()).trans_list do
          [] -> # t |> eval(n)
            if Fun.checked?(bd, wtp), do: - Tool.rw({:king, wtp}), else: 0.0
          mvl -> prune_red(mvl, wtp, {bd, h, hl}, n, init, init, initb, alpha, beta, mp)
        end ), else: t |> eval(0)
        |> M.save(mp, bd)
      r -> r
    end
  end

  defp prune_red([], _wtp, _t, _n, best, _, _, _alpha, _beta, _mp), do: best
  defp prune_red([mv | rest], wtp, {bd, h, hl}=t, n, best, init, initb, alpha, beta, mp) do
    sub = T.new([mv | h], hl + 1, Fun.apply(bd, mv))
    rm = ab_prune_crafted_(not wtp, sub, n-1, initb, init, alpha, beta, mp)
    bm = R.better_from(wtp, best, rm)
    {alpha, beta} = if wtp, do: {max(bm.eval, alpha), beta}, else: {alpha, min(bm.eval, beta)}
    if beta <= alpha, do: bm, else: prune_red(rest, wtp, t, n, bm, init, initb, alpha, beta, mp)
  end

  def eval(%T{board: board, history: hist}), do: {hist |> :lists.reverse, board |> Fun.evaluate()}

  def eval(%T{board: board, history: hist, history_len: hl}, level) do  # consider passing on wtp
    R.new(hist |> :lists.reverse, hl, board |> Fun.evaluate(), level, board |> Fun.white_to_play?)
  end

  defimpl Enumerable, for: Gchess.Trees.Simple do
    def count(%T{} = t), do: {:ok, (t |> T.expand_all) |> T.subnodes |> length}
    def member?(%T{} = t, %T{} = lf) do
      {:ok,
        t |> Enum.reduce_while(false, fn t, _ ->
          if t == lf, do: {:halt, true}, else: {:cont, false}
        end)}
    end

    def slice(%T{}), do: {:error, __MODULE__}
    # def reduce(%T{trans_list: nil} = t, {_, _} = a, fun),
    #   do: reduce_(t, T.expand_next(t), a, fun)
    # def reduce(%T{subnodes: sn, trans_list: tl, board: bd, history: h, history_len: hl}, {_, _} = a, fun),
    #   do: reducec_(sn ++ tl, {bd, h, hl + 1}, a, fun)

    # defp reduce_(_tp, _t, {:halt, acc}, _fun), do: {:halted, acc}
    # defp reduce_( tp,  t, {:suspend, acc}, fun), do: {:suspended, acc, &reduce_(tp, t, &1, fun)}
    # defp reduce_(  t,  t, {:cont, acc}, _fun), do: {:done, acc}
    # defp reduce_(_tp, %T{subnodes: [head | _]} = t, {:cont, acc}, fun), do: reduce_(t, T.expand_next(t), fun.(head, acc), fun)
    # defp reduce_(_tp, %T{subnodes: []}, {:cont, acc}, _fun), do: {:done, acc}

    def reduce(%T{board: bd, history: h, history_len: hl} = t, {_, _} = a, fun),
      do: ( t |> T.make_trans ).trans_list |> reducec_({bd, h, hl + 1}, a, fun)

    defp reducec_(_l, _b, {:halt, acc}, _fun), do: {:halted, acc}
    defp reducec_( l,  b,{:suspend, acc}, fun), do: {:suspended, acc, &reducec_(l, b, &1, fun)}
    defp reducec_([], _b, {:cont, acc}, _fun), do: {:done, acc}
    defp reducec_([head | tail], b, {:cont, acc}, fun), do: reducec_(tail, b, fun.(e_(head, b), acc), fun)

    defp e_(%Move{} = mv, {bd, h, hl_po}), do: T.new([mv | h], hl_po, Fun.apply(bd, mv))
    # defp e_(%T{} = t, _bd), do: t
  end
end

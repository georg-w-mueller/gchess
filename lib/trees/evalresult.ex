defmodule Gchess.Trees.Evalresult do
  defstruct history: [], eval: 0, level: 0, stop: false, hlen: 0
  alias Gchess.Trees.Evalresult, as: R

  # def new(history, eval, level) when is_list(history) and is_number(eval) and is_integer(level),
  #   do: %R{history: history, eval: eval, level: level, stop: abs(eval) > 900, hlen: length(history)}

  def new(history, hlen, eval, level, wtp) when is_list(history) and is_number(eval) and is_integer(level),
    do: %R{history: history, hlen: hlen, eval: eval, level: level, stop: stop_on(wtp, eval)}

  @stop_w  900
  @stop_b -900
  defp stop_on(true, val), do: val >= @stop_w
  defp stop_on(false, val), do: val <= @stop_b

  # def better_from(_max, %R{eval: e, hlen: l} = left, %R{eval: e, hlen: l}), do: left
  # def better_from(_max, %R{eval: e, hlen: ll} = left, %R{eval: e, hlen: lr} = right) do
  #   # IO.inspect(["equal results, different history length", ll, lr])
  #   if ll < lr, do: left, else: right   # prefer shorter history if evaluations are equal
  # end
  def better_from(true, %R{eval: el} = left, %R{eval: er}) when  el >= er, do: left
  def better_from(true, %R{}, %R{} = right), do: right

  def better_from(false, %R{eval: el} = left, %R{eval: er}) when el <= er, do: left
  def better_from(false, %R{}, %R{} = right), do: right

  def stop?(%R{stop: s}), do: s

  def cut?(true, _, %R{eval: eb}, %R{eval: ec}), do: eb <= ec
  def cut?(false, %R{eval: ea}, _, %R{eval: ec}), do: ec <= ea

  def worst_init(true), do: %R{eval: -8888}
  def worst_init(false), do: %R{eval: 8888}

end

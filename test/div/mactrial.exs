defmodule Mac do

  def lreduce([], _, acc), do: acc
  def lreduce([h | t], rf, acc), do: lreduce(t, rf, rf.(h, acc))

end

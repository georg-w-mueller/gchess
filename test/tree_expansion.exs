defmodule TreeExpansionTest do
  use ExUnit.Case
  doctest Gchess

  require Gchess.Moves.Steps
  alias Gchess.Boards.Simplet, as: S
  alias Gchess.Trees.Simplee, as: E

  test "basics" do
    t = E.new(S.new('8/6k1/8/8/8/8/1K6/8 '))

    assert  9 == t |> E.expand_to_level(1) |> E.count  ## 1 root + 8 king moves
    assert 73 == t |> E.expand_to_level(2) |> E.count  ## 1 root + 8 king moves + 8*8 replies
  end

end

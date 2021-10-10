defmodule CstepsTest do
  use ExUnit.Case
  doctest Gchess

  require Gchess.Moves.Steps
  alias Gchess.Moves.Csteps
  alias Gchess.Tools.Tool


  test "Basics" do
    # @A8 0
    # @H1 63
    # @C7 10
    assert "a8" == Tool.n_to_string(0)
    assert ["b8", "c8", "d8", "e8", "f8", "g8", "h8"] ==
      Csteps.right_from(0) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["b7", "c6", "d5", "e4", "f3", "g2", "h1"] ==
      Csteps.down_right_from(0) |> Enum.map(&(Tool.n_to_string(&1)))

    assert "h1" == Tool.n_to_string(63)
    assert ["g2", "f3", "e4", "d5", "c6", "b7", "a8"] ==
      Csteps.up_left_from(63) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["g1", "f1", "e1", "d1", "c1", "b1", "a1"] ==
      Csteps.left_from(63) |> Enum.map(&(Tool.n_to_string(&1)))

    assert "c7" == Tool.n_to_string(10)
    assert ["b7", "a7"] ==
      Csteps.left_from(10) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["d7", "e7", "f7", "g7", "h7"] ==
      Csteps.right_from(10) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["c8"] ==
      Csteps.up_from(10) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["c6", "c5", "c4", "c3", "c2", "c1"] ==
      Csteps.down_from(10) |> Enum.map(&(Tool.n_to_string(&1)))

    assert ["b8"] ==
      Csteps.up_left_from(10) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["d8"] ==
      Csteps.up_right_from(10) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["b6", "a5"] ==
      Csteps.down_left_from(10) |> Enum.map(&(Tool.n_to_string(&1)))
    assert ["d6", "e5", "f4", "g3", "h2"] ==
      Csteps.down_right_from(10) |> Enum.map(&(Tool.n_to_string(&1)))

  end
end

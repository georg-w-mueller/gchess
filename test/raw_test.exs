defmodule RawTest do
  use ExUnit.Case
  doctest Gchess

  alias Gchess.Moves.Raw
  # alias Gchess.Moves.Csteps
  alias Gchess.Tools.Tool

  test "knight moves" do
    assert "a8" == Tool.n_to_string(0)
    # assert ["B6", "C7"] ==
    #   Raw.raw(:knight, 0) |> Enum.map(&(Tool.n_to_string(hd( &1 ))))
    assert Tool.leql(["b6", "c7"],
      Raw.raw(:knight, 0) |> Enum.map(&(Tool.n_to_string(hd( &1 ))))
    )

    assert "h1" == Tool.n_to_string(63)
    # assert ["G3", "F2"] ==
    #   Raw.raw(:knight, 63) |> Enum.map(&(Tool.n_to_string(hd( &1 ))))
    assert Tool.leql(["g3", "f2"],
      Raw.raw(:knight, 63) |> Enum.map(&(Tool.n_to_string(hd( &1 ))))
    )

    assert "h8" == Tool.n_to_string(7)
    assert Tool.leql(["g6", "f7"],
      Raw.raw(:knight, 7) |> Enum.map(&(Tool.n_to_string(hd( &1 ))))
    )

    assert "c6" == Tool.n_to_string(18)
    assert Tool.leql(["d8", "b8", "e7", "e5", "d4", "b4", "a5", "a7"],
      Raw.raw(:knight, 18) |> Enum.map(&(Tool.n_to_string(hd( &1 ))))
    )
  end
end

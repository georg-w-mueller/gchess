defmodule Gchess.Moves.Steps do
  alias __MODULE__, as: S

  defmacro up() do
    quote do
      S.sevensteps(-8)
    end
  end
  defmacro down() do
    quote do
      S.sevensteps( 8)
    end
  end
  defmacro right() do
    quote do
      S.sevensteps(1)
    end
  end
  defmacro left() do
    quote do
      S.sevensteps(-1)
    end
  end
  defmacro up_right() do
    quote do
      S.sevencomb(S.up(), S.right())
    end
  end
  defmacro up_left() do
    quote do
      S.sevencomb(S.up(), S.left())
    end
  end
  defmacro down_right() do
    quote do
      S.sevencomb(S.down(), S.right())
    end
  end
  defmacro down_left() do
    quote do
      S.sevencomb(S.down(), S.left())
    end
  end
  defmacro sevensteps(stp) do
    quote do
      1..7 |> Enum.map(&(&1 * unquote(stp)))
    end
  end
  defmacro sevencomb(da, db) do
    quote do
      unquote(da) |> Stream.zip(unquote(db)) |> Enum.map(fn {a, b} -> a + b end)
    end
  end
end # module

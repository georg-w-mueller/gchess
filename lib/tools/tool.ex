defmodule Gchess.Tools.Tool do

  def file_rank(x) when is_integer(x) and x>=0 and x<=63 do
    {rem(x, 8), div(x, 8)}
  end

  # 0 -> "a8", 63 -> "h0"
  def n_to_string(x) do
    {f, r} = file_rank(x)
    [?a + f, ?8 - r] |> :binary.list_to_bin
  end

  def string_to_n(<<file::8, rank::8>>) when file >= ?a and file <=?h and rank >= ?1 and rank <= ?8 do
    (8 * (?8 - rank)) + (file - ?a)
  end
  def string_to_n([file, rank]) when file >= ?a and file <=?h and rank >= ?1 and rank <= ?8 do
    (8 * (?8 - rank)) + (file - ?a)
  end


  def leql(l, r) when is_list(l) and is_list(r) do
    MapSet.new(l) == MapSet.new(r) #length(l) == length(r) && l |> Enum.all?(fn le -> r |> Enum.any?(&(&1 == le)) end)
  end

  def castle?(true, cops), do: cops |> Enum.any?(fn c -> c == ?K || c == ?Q end)
  def castle?(false, cops ), do: cops |> Enum.any?(fn c -> c == ?k || c == ?q end)

  def castle_short?(true, cops), do: cops |> Enum.any?(fn c -> c == ?K end)
  def castle_short?(false, cops), do: cops |> Enum.any?(fn c -> c == ?k end)

  def castle_long?(true, cops), do: cops |> Enum.any?(fn c -> c == ?Q end)
  def castle_long?(false, cops), do: cops |> Enum.any?(fn c -> c == ?q end)

  def castle_kill(true),  do: 'KQ'
  def castle_kill(false), do: 'kq'
  def castle_kill_short(true),  do: 'K'
  def castle_kill_short(false), do: 'k'
  def castle_kill_long(true),   do: 'Q'
  def castle_kill_long(false),  do: 'q'

  def rw({:pawn, true}), do: 1
  def rw({:pawn, false}), do: -1

  def rw({:rook, true}), do: 4
  def rw({:rook, false}), do: -4

  def rw({:knight, true}), do: 3
  def rw({:knight, false}), do: -3

  def rw({:bishop, true}), do: 3
  def rw({:bishop, false}), do: -3

  def rw({:queen, true}), do: 8
  def rw({:queen, false}), do: -8

  def rw({:king, true}), do: 999
  def rw({:king, false}), do: -999

  def rw(_), do: 0

  def hwrp(white, n), do: hit_would_require_pawn_on(n, white, file_rank(n))

  # fields on rank >= 6 cannot be hit by any white pawn
  defp hit_would_require_pawn_on(_n, true, {_f, r}) when r >= 6, do: []
  # fields on rank <= 1  cannot be hit by any black pawn
  defp hit_would_require_pawn_on(_n, false, {_f, r}) when r <= 1, do: []
  defp hit_would_require_pawn_on(n, white_pawn_hitting, {f, _r}) do
    {w, e} = phts(white_pawn_hitting)
    pwest = n + w; peast = n + e
    apw = if rem(pwest, 8) < f, do: [pwest], else: []
    if rem(peast, 8) > f, do: [peast | apw], else: apw
  end

  defp phts(true), do: {7, 9}
  defp phts(false), do: {-9, -7}

end

defmodule Gchess.Moves.Move do
  alias __MODULE__, as: M

  defstruct is_white: true, from: 0, to: 0, chessman: :invalid, rw_change: 0, options: [] #, promote_to: nil, ep_file: nil, hit_piece: nil, ep_hit: false

  def new_quiet(piece, is_white, from, to, cc \\ nil) when is_atom(piece) and is_boolean(is_white)
      and from >=0 and from <=63 and to >= 0 and to <=63 and from != to
  do
    if cc do
      %M{chessman: piece, is_white: is_white, from: from, to: to, options: [castle_kill: cc]}
    else
      %M{chessman: piece, is_white: is_white, from: from, to: to}
    end
  end

  def new_hit(piece, is_white, from, to, hit_piece, cc \\ nil) when is_atom(hit_piece) do
    m = new_quiet(piece, is_white, from, to, cc)
    %M{m | options: Keyword.put(m.options, :hit_piece, hit_piece), rw_change: rwc(is_white, hit_piece)}
  end

  def new_pawn_double(is_white, from, to) do
    m = new_quiet(:pawn, is_white, from, to)
    %M{m | options: [{:ep_field, from + div((to - from), 2)}]}
  end

  def new_ep_hit(is_white, from, to, ep_hit_pos) do
    m = new_hit(:pawn, is_white, from, to, :pawn)
    %M{m | options: Keyword.put(m.options, :ep_hit, ep_hit_pos)}
  end

  def new_promotion(is_white, from, to, promote_to) when is_atom(promote_to) do
    m = new_quiet(:pawn, is_white, from, to)
    %M{m | options: [{:promote_to, promote_to}], rw_change: rwc(is_white, promote_to) + rwc(not is_white, :pawn) }
  end

  def new_hit_promotion(is_white, from, to, hit_piece, promote_to) when is_atom(hit_piece) do
    m = new_promotion(is_white, from, to, promote_to)
    %M{m | options: Keyword.put(m.options, :hit_piece, hit_piece),
      rw_change: m.rw_change + rwc(is_white, hit_piece)}
  end

  def new_king_short(is_white, from, to, {_rfrom, _rto} = rm, cc) do
    m = new_quiet(:king, is_white, from, to)
    %M{m | options: [castle_short: true, castle_kill: cc, rook_move: rm]}
  end

  def new_king_long(is_white, from, to, {_rfrom, _rto} = rm, cc) do
    m = new_quiet(:king, is_white, from, to)
    %M{m | options: [castle_long: true, castle_kill: cc, rook_move: rm]}
  end

  def sort(moves, true), do: moves |> Enum.sort(&( (&1).rw_change >= (&2).rw_change ))
  def sort(moves, false), do: moves |> Enum.sort(&( (&1).rw_change <= (&2).rw_change ))

  # white to play; black pawn was hit
  defp rwc(true, :pawn), do: 1
  defp rwc(false, :pawn), do: -1

  defp rwc(true, :rook), do: 4
  defp rwc(false, :rook), do: -4

  defp rwc(true, :knight), do: 3
  defp rwc(false, :knight), do: -3

  defp rwc(true, :bishop), do: 3
  defp rwc(false, :bishop), do: -3

  defp rwc(true, :queen), do: 8
  defp rwc(false, :queen), do: -8

  defp rwc(true, :king), do: 999
  defp rwc(false, :king), do: -999

end

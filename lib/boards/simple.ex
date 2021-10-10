defmodule Gchess.Boards.Simple do
  alias __MODULE__, as: S
  alias Gchess.Moves.Raw
  alias Gchess.Moves.Move
  alias Gchess.Tools.Tool
  alias Gchess.Tools.Binex

  defstruct board: nil, white_to_play: true, ep_field: nil, castle: nil, raw_value: 0

@empty	    0
@rook_w	    2
@knight_w   3
@bishop_w	  4
@queen_w	  5
@king_w	    6
@pawn_w	    7

@rook_b	    8
@knight_b   9
@bishop_b	  10
@queen_b	  11
@king_b	    12
@pawn_b	    13

@valid_cl 'KQkq'

  def plain(), do: %S{board: <<0::512>>}
  def place(%S{board: board} = b, {_what, _white} = chessman, at) when at >=0 and at <=63 do
    %S{ b | board: Binex.ex(board, at, mapcc_r(chessman))}
  end
  def place(%S{} = b, chessman, at) do
    place(b, chessman, Tool.string_to_n(at))
  end

  def clear(%S{board: board} = b, at) when at >=0 and at <=63 do
    %S{ b | board: Binex.ex(board, at, @empty)}
  end
  def clear(%S{} = b, at) do
    clear(b, Tool.string_to_n(at))
  end

  def move(b, from, to, rw_change \\ 0)
  def move(%S{board: board, white_to_play: wtp, raw_value: rw} = b, from, to, rwc) when from >= 0 and from <=63 and to >=0 and to <=63 and from != to do
    %S{ b | board: trans(board, from, to), white_to_play: not wtp, ep_field: nil, raw_value: rw + rwc}
  end
  def move(%S{} = b, from, to, rw_change) do
    move(b, Tool.string_to_n(from), Tool.string_to_n(to), rw_change)
  end

  def trans(board, from, to) do
    Binex.ex(board, from, @empty) |> Binex.ex(to, :binary.at(board, from))
  end

  def new() do
    new(stpos()) |> set_castle(@valid_cl)
  end
  def new(bd, wtb \\ true)
  def new(fen, wtb) when is_list(fen) do
    %S{board: fen_to_pos(fen), white_to_play: wtb}
  end
  def new(bd, wtb) when is_binary(bd) do
    %S{board: bd, white_to_play: wtb}
  end
  def new(%{} = mp, wtp) do
    (mp |> Enum.reduce( %{ plain() | white_to_play: wtp}, fn {k, v}, b -> place(b, v, k) end))
  end

  def set_wtp(%S{white_to_play: wtp} = bd, wtp), do: bd
  def set_wtp(%S{} = bd, white_tp) when is_boolean(white_tp), do: %S{bd | white_to_play: white_tp}

  def toggle_stp(%S{white_to_play: wtb} = b), do: %S{ b | white_to_play: not wtb }

  def set_ep_field(%S{} = b, f) when f >= 0 and f <= 63 do
    %S{ b | ep_field: f}
  end

  def set_castle(%S{} = b, cl) when is_list(cl) and length(cl) <= 4 do
    case cl |> Enum.all?(fn c -> Enum.any?(@valid_cl, fn v -> v == c end) end) do
      true -> %S{ b | castle: cl}
      false -> raise "Invalid castling-settings #{IO.inspect(cl)}. Allowed: #{IO.inspect(@valid_cl)}}"
    end
  end

  def clear_castle(%S{castle: nil} = b, _cl), do: b
  def clear_castle(%S{castle: []} = b, _cl), do: b
  def clear_castle(%S{castle: ocl} = b, cl) when is_list(cl) do
    %S{ b | castle: ocl |> Enum.filter(fn o -> cl |> Enum.any?( fn c -> c != o end) end)}
  end

  # quiet move from black or white (no hit, no pawn-double, no castling, no promotion)
  def apply(%S{white_to_play: wtp} = b, %Move{is_white: wtp, from: f, to: t, options: []}) do
    move(b, f, t)
  end

  def apply(%S{white_to_play: wtp, ep_field: ep_pos} = b, %Move{is_white: wtp, from: f, to: t,
          options: opts, rw_change: rwc}) do
    opts |> Enum.reduce( move(b, f, t, rwc), fn
      {:castle_kill, ck}, cb -> cb |> clear_castle(ck)
      {:castle_long, _}, cb -> cb  # consistency check
      {:castle_short, _}, cb -> cb  # consistency check
      {:hit_piece, _hit_piece}, cb -> cb
      {:rook_move, {from, to}}, cb -> %S{cb | board: cb.board |> trans(from, to)}
      {:ep_hit, ^ep_pos}, cb -> cb |> clear(ep_pos)
      {:ep_field, epf}, cb -> cb |> set_ep_field(epf)
      {:promote_to, fig}, cb -> cb |> place({fig, wtp}, t)
    end)
  end

  def genraw(%S{board: board, white_to_play: wtb}, fig, n) when is_atom(fig) and n>=0 and n <=63 do
    rms = Raw.raw(fig, n)
    rms |> Enum.flat_map(fn d ->
      d |> Enum.reduce_while([],
        fn n, acc ->
          t = :binary.at(board, n) #get(board, n)
          case empty?(t) do
            true -> {:cont, acc ++ [n]}
            _ ->
              case wtb do
                true ->   if black?(t), do: {:halt, acc ++ [{n, t}] }, else: {:halt, acc}
                false ->  if white?(t), do: {:halt, acc ++ [{n, t}] }, else: {:halt, acc}
              end
          end
      end)
    end)
  end

  defp gen_raw_(wtp, b, fig, n, kill_castle) do
    genraw(b, fig, n)
    |> Enum.map(fn
        {to, hfig} -> {fa, _} = mapcc(hfig); Move.new_hit(fig, wtp, n, to, fa, kill_castle)
        to -> Move.new_quiet(fig, wtp, n, to, kill_castle)
    end)
  end

  # either no castling possible or uncritical square
  def genraw_moves(%S{white_to_play: wtp, castle: castle} = b, fig, n) when is_nil(castle) or castle == [] or
      n not in [0, 4, 7, 56, 60, 63] do
    gen_raw_(wtp, b, fig, n, nil)
  end

  # king on init
  def genraw_moves(%S{white_to_play: wtp, castle: castle} = b, :king, n) when n in [4, 60] do
    gen_raw_(wtp, b, :king, n, castle_kill(wtp, castle))
  end

  # kingside rook on init
  def genraw_moves(%S{white_to_play: wtp, castle: castle} = b, :rook, n) when n in [7, 63] do
    gen_raw_(wtp, b, :rook, n, castle_kill_short(wtp, castle))
  end

  # queenside rook on init
  def genraw_moves(%S{white_to_play: wtp, castle: castle} = b, :rook, n) when n in [0, 56] do
    gen_raw_(wtp, b, :rook, n, castle_kill_long(wtp, castle))
  end

  # else
  def genraw_moves(%S{white_to_play: wtp} = b, fig, n) do
    gen_raw_(wtp, b, fig, n, nil)
  end

  defp castle_kill(wtp, cops) do
    case Tool.castle?(wtp, cops) do
      true -> Tool.castle_kill(wtp)
      _ -> nil
    end
  end

  defp castle_kill_short(wtp, cops) do
    case Tool.castle_short?(wtp, cops) do
      true -> Tool.castle_kill_short(wtp)
      _ -> nil
    end
  end

  defp castle_kill_long(wtp, cops) do
    case Tool.castle_long?(wtp, cops) do
      true -> Tool.castle_kill_long(wtp)
      _ -> nil
    end
  end

  def is_hit?(%S{board: board}, n, by_white) when n >= 0 and n <= 63 and is_boolean(by_white) do
    hit_by_pawn?(board, n, by_white) ||
    htp(by_white) |>
    Enum.any?(fn {fig, tf} ->
      Raw.raw(fig, n) |> Enum.any?(fn dim ->
        dim |> Enum.reduce_while(false, fn t,_ ->
          case :binary.at(board, t) do
            @empty -> {:cont, false}
            x -> if tf.(x), do: {:halt, true}, else: {:halt, false}
          end
        end)
      end)
    end)
  end

  def hit_by_pawn?(board, n, white) do
    tp = if white, do: @pawn_w, else: @pawn_b
    hit_would_require_pawn_on(n, white, Tool.file_rank(n))
    |> Enum.any?(fn t -> :binary.at(board, t) == tp end)
  end

  # fields on rank >= 6 cannot be hit by any white pawn
  def hit_would_require_pawn_on(_n, true, {_f, r}) when r >= 6, do: []
  # fields on rank <= 1  cannot be hit by any black pawn
  def hit_would_require_pawn_on(_n, false, {_f, r}) when r <= 1, do: []
  def hit_would_require_pawn_on(n, white_pawn_hitting, {f, _r}) do
    {w, e} = phts(white_pawn_hitting)
    pwest = n + w; peast = n + e
    apw = if rem(pwest, 8) < f, do: [pwest], else: []
    if rem(peast, 8) > f, do: [peast | apw], else: apw
  end

  def phts(true), do: {7, 9}
  def phts(false), do: {-9, -7}

  def htp(true) do
    [ {:rook, fn t -> t == @rook_w || t == @queen_w end},
      {:bishop, fn t -> t == @bishop_w || t == @queen_w end},
      {:knight, fn t -> t == @knight_w end},
      {:king, fn t -> t == @king_w end}
    ]
  end
  def htp(false) do
    [ {:rook, fn t -> t == @rook_b || t == @queen_b end},
      {:bishop, fn t -> t == @bishop_b || t == @queen_b end},
      {:knight, fn t -> t == @knight_b end},
      {:king, fn t -> t == @king_b end}
    ]
  end

  def empty?(@empty), do: true
  def empty?(_), do: false

  for f <- [@rook_w,  @knight_w,  @bishop_w,  @queen_w,  @king_w, @pawn_w] do
    def white?(unquote(f)), do: true
  end
  def white?(_), do: false

  for f <- [@rook_b,  @knight_b,  @bishop_b,  @queen_b,  @king_b, @pawn_b] do
    def black?(unquote(f)), do: true
  end
  def black?(_), do: false

  def get(%S{board: board}, x), do: :binary.at(board, x)
  def get(board, x), do: :binary.at(board, x)

  def white?(board, x), do: white?( get(board, x) )
  def black?(board, x), do: black?( get(board, x) )
  def empty?(board, x), do: empty?( get(board, x) )

  def stpos() do
    # quote do
      [
        @rook_b, @knight_b, @bishop_b, @queen_b, @king_b, @bishop_b, @knight_b, @rook_b,
        @pawn_b, @pawn_b, @pawn_b, @pawn_b, @pawn_b, @pawn_b, @pawn_b, @pawn_b,
        @empty, @empty, @empty, @empty, @empty, @empty, @empty, @empty,
        @empty, @empty, @empty, @empty, @empty, @empty, @empty, @empty,
        @empty, @empty, @empty, @empty, @empty, @empty, @empty, @empty,
        @empty, @empty, @empty, @empty, @empty, @empty, @empty, @empty,
        @pawn_w, @pawn_w, @pawn_w, @pawn_w, @pawn_w, @pawn_w, @pawn_w, @pawn_w,
        @rook_w, @knight_w, @bishop_w, @queen_w, @king_w, @bishop_w, @knight_w, @rook_w
      ] |> S.compress
    # end
  end

  def compress(l), do: for f <- l, do: <<f::8>>, into: <<>>

  def kingpos_b(bin), do: bin |> :binary.match(<<@king_b :: 8>>) |> elem(0)
  def kingpos_w(bin), do: bin |> :binary.match(<<@king_w :: 8>>) |> elem(0)

  @fen_init 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
  def stpos_fen(), do: fen_to_pos(@fen_init)

  def fen_to_pos(fen), do: ftp_(fen, [])
  defp ftp_([47 | t], res), do: ftp_(t, res)  # /
  defp ftp_([32 | _], res), do: compress(res)  # blank
  defp ftp_([h | t], res) do
    case map(h) do
      l when is_list(l) -> ftp_(t, res ++ l)
      s -> ftp_(t, res ++ [s])
    end
  end

  def map(n) when n >= 49 and n <= 56 do  # '1' .. '8'
    [@empty] |> Stream.cycle |> Enum.take(n - 48)
  end
  def map(?r), do: @rook_b
  def map(?n), do: @knight_b
  def map(?b), do: @bishop_b
  def map(?q), do: @queen_b
  def map(?k), do: @king_b
  def map(?p), do: @pawn_b

  def map(?R), do: @rook_w
  def map(?N), do: @knight_w
  def map(?B), do: @bishop_w
  def map(?Q), do: @queen_w
  def map(?K), do: @king_w
  def map(?P), do: @pawn_w

  def map(f), do: raise "Cannot map #{IO.inspect(f)}"

  @mapping  [ {@empty, :empty},
    {@rook_w, {:rook, true}},
    {@knight_w, {:knight, true}},
    {@bishop_w, {:bishop, true}},
    {@queen_w, {:queen, true}},
    {@king_w, {:king, true}},
    {@pawn_w, {:pawn, true}},
    {@rook_b, {:rook, false}},
    {@knight_b, {:knight, false}},
    {@bishop_b, {:bishop, false}},
    {@queen_b, {:queen, false}},
    {@king_b, {:king, false}},
    {@pawn_b, {:pawn, false}}
  ]

  for {internal, external} <- @mapping do
    def mapcc(unquote(internal)), do: unquote(external)
  end
  def mapcc(f), do: raise "Cannot mapcc #{IO.inspect(f)}"

  for {internal, external} <- @mapping do
    def mapcc_r(unquote(external)), do: unquote(internal)
  end
  def mapcc_r(f), do: raise "Cannot mapcc_r #{IO.inspect(f)}"

  defimpl Gchess.Boards.Fun do
    def get_chm_and_color(target, n), do: @for.get(target, n) |> @for.mapcc
    def getmany_chm_and_color(target, enum), do: enum |> Enum.map(fn n -> @for.get(target, n) |> @for.mapcc end)
    def white_to_play?(target), do: target.white_to_play
    def kingpos_b(target), do: @for.kingpos_b(target)
    def kinkpos_w(target), do: @for.kingpos_b(target)
    def ep_field(target), do: target.ep_field
    def castle(target), do: target.castle
    def genraw_moves(target, fig, n), do: @for.genraw_moves(target, fig, n)
    def set_wtp(target, white_to_play), do: @for.set_wtp(target, white_to_play)
    def are_empty?(target, enum), do: enum |> Enum.all?(fn n -> @for.get(target, n) == 0 end) # @empty!

    def is_hit?(target, n, by_white), do: @for.is_hit?(target, n, by_white)
    def is_any_hit?(target, enum, by_white), do: enum |> Enum.any?(fn t -> @for.is_hit?(target, t, by_white) end)

    def clear(_target, _at), do: raise "clear not implemented for #{IO.inspect(@for)}"
    def gen_moves(_target), do: raise "gen_moves not implemented for #{IO.inspect(@for)}"
    def apply(_target, _move), do: raise "apply not implemented for #{IO.inspect(@for)}"
    def evaluate(target), do: target.raw_value
    def checked?(_target, _wtp), do: raise "checked? not implemented for #{IO.inspect(@for)}"
  end
  # defimpl Area.Shape.Fun, for: P do
  #   def area(target), do: target.area  # @for.min_x(target)
  #   def cog(target), do: target.cog  # @for.max_x(target)
  #   def inside?(target, point), do: target.inside?.(point)
  # end
end # module

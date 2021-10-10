defmodule Gchess.Boards.Simplet do
  alias __MODULE__, as: S
  alias Gchess.Moves.Raw
  alias Gchess.Moves.Move
  alias Gchess.Tools.Tool
  alias Gchess.Moves.Kingmoves
  alias Gchess.Moves.Pawnmoves

  import Kernel, except: [apply: 2]

  defstruct board: nil, white_to_play: true, ep_field: nil, castle: [],
    raw_value: 0, king_white: nil, king_black: nil

  def equal(%S{board: b, white_to_play: wtp, ep_field: epf, castle: cll},
        %S{board: b, white_to_play: wtp, ep_field: epf, castle: clr}) do
    Tool.leql(cll, clr)
  end
  def equal(_, _), do: false

defmacro empty, do: :empty

defmacro rook_w, do: {:rook, true}
defmacro knight_w, do: {:knight, true}
defmacro bishop_w, do: {:bishop, true}
defmacro queen_w, do: {:queen, true}
defmacro king_w, do: {:king, true}
defmacro pawn_w, do: {:pawn, true}

defmacro rook_b, do: {:rook, false}
defmacro knight_b, do: {:knight, false}
defmacro bishop_b, do: {:bishop, false}
defmacro queen_b, do: {:queen, false}
defmacro king_b, do: {:king, false}
defmacro pawn_b, do: {:pawn, false}

@valid_cl 'KQkq'
@empty_board Stream.cycle([:empty]) |> Enum.take(64) |> :erlang.list_to_tuple ## take care -> :empty

  def plain(), do: %S{board: @empty_board}

  @compile {:inline, iset: 3}
  defp iset(tuple, at, what), do: :erlang.setelement(at +  1, tuple, what)

  @compile {:inline, iclear: 2}
  defp iclear(tuple, at), do: tuple |> iset(at, empty())

  @compile {:inline, iget: 2}
  defp iget(tuple, at), do: elem(tuple, at)

  @compile {:inline, itrans: 3}
  defp itrans(tuple, from, to) do
    tuple |> iset(to, iget(tuple, from)) |> iclear(from)
  end

  @compile {:inline, empty?: 1}
  def empty?(x), do: x == empty()
  # def empty?(:empty), do: true
  # def empty?(_), do: false

  @compile {:inline, white?: 1}
  def white?({_fig, true}), do: true
  def white?(_), do: false

  @compile {:inline, black?: 1}
  def black?({_fig, false}), do: true
  def black?(_), do: false

  def place(%S{board: board} = b, {_what, _white} = chessman, at) when at >=0 and at <=63 do
    %S{ b | board: board |> iset(at, chessman)}
  end
  def place(%S{} = b, chessman, at) do
    place(b, chessman, Tool.string_to_n(at))
  end

  def clear(%S{board: board} = b, at) when at >=0 and at <=63 do
    %S{ b | board: board |> iclear(at)}
  end
  def clear(%S{} = b, at) do
    clear(b, Tool.string_to_n(at))
  end

  def move(b, from, to, rw_change \\ 0)
  def move(%S{board: board, white_to_play: wtp, raw_value: rw} = b, from, to, rwc) when from >= 0 and from <=63 and to >=0 and to <=63 do
    %S{ b | board: board |> itrans(from, to), white_to_play: not wtp, ep_field: nil, raw_value: rw + rwc}
  end
  def move(%S{} = b, from, to, rw_change) do
    move(b, Tool.string_to_n(from), Tool.string_to_n(to), rw_change)
  end

  def new() do
    new(stpos()) |> set_castle(@valid_cl) |> set_rawandkings
  end
  def new(bd, wtb \\ true)
  def new(fen, wtb) when is_list(fen) do
    %S{board: fen_to_pos(fen), white_to_play: wtb} |> set_rawandkings
  end
  def new(bd, wtb) when is_tuple(bd) do
    %S{board: bd, white_to_play: wtb} |> set_rawandkings
  end
  def new(%{} = mp, wtp) do
    (mp |> Enum.reduce( %{ plain() | white_to_play: wtp}, fn {k, v}, b -> place(b, v, k) end)) |> set_rawandkings
  end

  def set_rawandkings(%S{board: board} = bd) do
    {rv, wkp, bkp} = 0..63
    |> Enum.reduce({0, nil, nil}, fn n, {r, wkp, bkp} ->
      cm = iget(board, n)
      {r + Tool.rw(iget(board, n)),
        (if cm == king_w(), do: n, else: wkp),
        (if cm == king_b(), do: n, else: bkp)
      }
    end)
    %S{ bd | raw_value: rv, king_white: wkp, king_black: bkp}
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
    %S{ b | castle: ocl |> Enum.filter(fn o -> not (cl |> Enum.any?( fn c -> c == o end)) end)}
  end

  def apply(bd, %Move{is_white: true, chessman: :king, to: to} = mv) do
    %S{ appl_(bd, mv) | king_white: to}
  end
  def apply(bd, %Move{is_white: false, chessman: :king, to: to} = mv) do
    %S{ appl_(bd, mv) | king_black: to}
  end
  # def apply(%S{white_to_play: wtp, king_white: wkp, king_black: bkp} = bd, %Move{} = mv) do
  def apply(%S{} = bd, %Move{} = mv) do
    # tpos = if wtp, do: wkp, else: bkp
    # res = appl_(bd, mv)
    # if res |> is_hit?(tpos, not wtp), do: %S{res | valid: false}, else: res
    appl_(bd, mv)   # no check-check required -> gen_moves does the filtering now
  end

  # quiet move from black or white (no hit, no pawn-double, no castling, no promotion)
  defp appl_(%S{white_to_play: wtp} = b, %Move{is_white: wtp, from: f, to: t, options: []}) do
    move(b, f, t)
  end

  defp appl_(%S{white_to_play: wtp} = b, %Move{is_white: wtp, from: f, to: t,
          options: opts, rw_change: rwc}) do
    opts |> Enum.reduce( move(b, f, t, rwc), fn
      {:castle_kill, ck}, cb -> cb |> clear_castle(ck)
      {:castle_long, _}, cb ->  cb  # consistency check
      {:castle_short, _}, cb -> cb  # consistency check
      {:hit_piece, _hit_piece}, cb -> cb
      {:rook_move, {from, to}}, cb -> %S{cb | board: cb.board |> itrans(from, to)}
      {:ep_hit, ep_pos}, cb -> cb |> clear(ep_pos)
      {:ep_field, epf}, cb -> cb |> set_ep_field(epf)
      {:promote_to, fig}, cb -> cb |> place({fig, wtp}, t)
    end)
  end

  def gen_moves(%S{white_to_play: wtp, board: board} = bd) do
    ps = get_pins_n_alines(bd)
    0..63 |> Enum.reduce([], fn n, res ->
      case board |> iget(n) do
        :empty -> res
        {:king, ^wtp} -> [ Kingmoves.moves_from(bd, n, wtp) | res]
        {:pawn, ^wtp} -> [ Pawnmoves.moves_from(bd, n, wtp) |> filter_pinned(ps) | res]
        {fig, ^wtp} -> [ genraw_moves(bd, fig, n) |> filter_pinned(ps) | res]
        _ -> res
      end
    end) |> Enum.flat_map(&(&1))
  end

  def gen_moves_p(%S{white_to_play: wtp, board: board} = bd) do
    ps = get_pins_n_alines(bd)
    tn = fn x -> Task.async(fn -> x end) end
    0..63 |> Enum.reduce([], fn n, res ->
      case board |> iget(n) do
        :empty -> res
        {:king, ^wtp} -> [ tn.( Kingmoves.moves_from(bd, n, wtp) ) | res]
        {:pawn, ^wtp} -> [ tn.( Pawnmoves.moves_from(bd, n, wtp) |> filter_pinned(ps) ) | res]
        {fig, ^wtp} -> [ tn.( genraw_moves(bd, fig, n) |> filter_pinned(ps)) | res]
        _ -> res
      end
    end) |> Task.yield_many |> Stream.map(fn {_, {:ok, res}} -> res end) |> Enum.flat_map(&(&1))
  end

  def filter_pinned(mvs, ps) when ps == %{}, do: mvs
  def filter_pinned(mvs, pinnings) do
    alines = pinnings |> Enum.reduce([],
    fn {k, v}, acc when k < 0 -> [v | acc]
          {_k, _v}, acc -> acc
    end)
    # IO.inspect(alines)
    filter_p(mvs, pinnings, [], alines)
  end

  def filter_p([], _ps, res, _alines), do: res
  def filter_p( [ %Move{from: from, to: to} = move | tail], ps, res, alines) do
    case {Map.get(ps, from), voids_all_alines(to, alines)} do
      {_,  false} -> filter_p(tail, ps, res, alines)
      {nil, true} -> filter_p(tail, ps, [move | res], alines)
      {tl, true} ->
        case tl |> Enum.any?(fn t -> t == to end) do
          true -> filter_p(tail, ps, [move | res], alines)
          false -> filter_p(tail, ps, res, alines)
        end
    end
  end

  def voids_all_alines(to, alines) do
    alines |> Enum.all?(fn l -> l |> Enum.any?(fn sto -> sto == to end) end)
  end

  def genraw(%S{board: board, white_to_play: wtp}, fig, n) when is_atom(fig) and n>=0 and n <=63 do
    Raw.raw(fig, n) |> reduce_dims([], board, wtp)
  end

  defp reduce_dims([], acc, _board, _wtp), do: acc
  defp reduce_dims([d | rest], acc, board, wtp) do
    reduce_dims(rest,
                reduce_dim(d, acc, board, wtp),
                board, wtp)
  end

  defp reduce_dim([], acc, _board, _wtp), do: acc #|> :lists.reverse()
  defp reduce_dim([n | rest], acc, board, wtp) do
    t = board |> iget(n)
    case empty?(t) do
      true -> reduce_dim(rest, [n | acc], board, wtp)
      _ ->
        case wtp do
          true ->   if black?(t), do:  [{n, t} | acc], else: acc
          false ->  if white?(t), do:  [{n, t} | acc], else: acc
        end
    end
  end

  defp gen_raw_(wtp, b, fig, n, kill_castle) do
    genraw(b, fig, n)
    |> Enum.map(fn
        {to, {fa, _}} -> Move.new_hit(fig, wtp, n, to, fa, kill_castle)
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

  def get_pins_n_alines(%S{board: board, white_to_play: wtp, king_white: kw, king_black: kb}) do
    kp = if wtp, do: kw, else: kb
    # find own pieces located on relevant dims, intercepting opposite piece and own king
    pinnedcf = if wtp, do: fn f -> white?(f) end, else: fn f -> black?(f) end
    pinnercf = if wtp do
      { fn f -> f in [rook_b(), queen_b()] end, fn f -> f in [bishop_b(), queen_b()] end }
    else
      { fn f -> f in [rook_w(), queen_w()] end, fn f -> f in [bishop_w(), queen_w()] end }
    end
    {op, okn} = if wtp, do: {pawn_b(), knight_b()}, else: {pawn_w(), knight_w()}
    pot_check_giving_pawn_pos = Raw.hwr_pawn(kp, not wtp) |> Enum.filter( fn x -> iget(board, x) == op end)
    pot_check_giving_pawn_knight = Raw.hwr_knight(kp) |> Enum.filter( fn x -> iget(board, x) == okn end)

    pgc = case pot_check_giving_pawn_pos ++ pot_check_giving_pawn_knight do
      [] -> %{}
      [hpp] -> %{ -hpp - 1 => [hpp]}
      _ -> raise "More then one pawn/knight giving check?"
    end

    get_pinnig(board, Raw.raw(:rook, kp), pinnedcf, pinnercf |> elem(0))
    |> Map.merge(get_pinnig(board, Raw.raw(:bishop, kp), pinnedcf, pinnercf |> elem(1)))
    |> Map.merge(pgc)
  end

  def get_pinnig(board, dims, pinnedcf, pinnercf) do
    for dim <- dims do
      get_pinned(board, dim, pinnedcf, pinnercf, [])
    end |> Enum.reduce(%{}, fn r, all -> Map.merge(r, all) end)
  end

  def get_pinned(_board, [], _pinnedcf, _pinnercf, _coll), do: %{}
  def get_pinned(board, [n | rest], pinnedcf, pinnercf, coll) do
    case iget(board, n) do
      :empty -> get_pinned(board, rest, pinnedcf, pinnercf, [n | coll])
      x ->  if pinnedcf.(x) do
              get_pinner(board, n, rest, pinnercf, coll)
            else
              if pinnercf.(x), do: %{ (- n) - 1 => [n | coll]}, else: %{}
            end
    end
  end

  def get_pinner(_board, _n, [], _pinnercf, _coll), do: %{}
  def get_pinner(board, n, [x | rest], pinnercf, coll) do
    case iget(board, x) do
      :empty -> get_pinner(board, n, rest, pinnercf, [x | coll])
      f -> if pinnercf.(f), do: %{n => [x | coll]}, else: %{}
    end
  end

  def checked?(%S{king_white: kp} = b, true), do: b |> is_hit?(kp, false)
  def checked?(%S{king_black: kp} = b, false), do: b |> is_hit?(kp, true)

  def is_hit?(%S{board: board}, n, by_white) when n >= 0 and n <= 63 and is_boolean(by_white) do
    hit_by_pawn?(board, n, by_white) ||
    htp(by_white) |>
    Enum.any?(fn {fig, tf} ->
      Raw.raw(fig, n) |> Enum.any?(fn dim ->
        dim |> Enum.reduce_while(false, fn t,_ ->
          case iget(board, t) do
            :empty -> {:cont, false}
            x -> if tf.(x), do: {:halt, true}, else: {:halt, false}
          end
        end)
      end)
    end)
  end

  def hit_by_pawn?(board, n, white) do
    tp = if white, do: {:pawn, true}, else: {:pawn, false}
    Raw.hwr_pawn(n, white)  # hit_would_require_pawn_on(n, white, Tool.file_rank(n))
    |> Enum.any?(fn t -> iget(board, t) == tp end)
  end

  # # fields on rank >= 6 cannot be hit by any white pawn
  # def hit_would_require_pawn_on(_n, true, {_f, r}) when r >= 6, do: []
  # # fields on rank <= 1  cannot be hit by any black pawn
  # def hit_would_require_pawn_on(_n, false, {_f, r}) when r <= 1, do: []
  # def hit_would_require_pawn_on(n, white_pawn_hitting, {f, _r}) do
  #   {w, e} = phts(white_pawn_hitting)
  #   pwest = n + w; peast = n + e
  #   apw = if rem(pwest, 8) < f, do: [pwest], else: []
  #   if rem(peast, 8) > f, do: [peast | apw], else: apw
  # end

  # def phts(true), do: {7, 9}
  # def phts(false), do: {-9, -7}

  def htp(true) do
    [ {:rook, fn t -> t == rook_w() || t == queen_w() end},
      {:bishop, fn t -> t == bishop_w() || t == queen_w() end},
      {:knight, fn t -> t == knight_w() end},
      {:king, fn t -> t == king_w() end}
    ]
  end
  def htp(false) do
    [ {:rook, fn t -> t == rook_b() || t == queen_b() end},
      {:bishop, fn t -> t == bishop_b() || t == queen_b() end},
      {:knight, fn t -> t == knight_b() end},
      {:king, fn t -> t == king_b() end}
    ]
  end

  def get(%S{board: board}, x), do: iget(board, x)
  def get(board, x) when is_tuple(board), do: iget(board, x)

  def white?(board, x), do: white?( get(board, x) )
  def black?(board, x), do: black?( get(board, x) )
  def empty?(board, x), do: empty?( get(board, x) )

  def stpos() do
      [
        rook_b(), knight_b(), bishop_b(), queen_b(), king_b(), bishop_b(), knight_b(), rook_b(),
        pawn_b(), pawn_b(), pawn_b(), pawn_b(), pawn_b(), pawn_b(), pawn_b(), pawn_b(),
        empty(), empty(), empty(), empty(), empty(), empty(), empty(), empty(),
        empty(), empty(), empty(), empty(), empty(), empty(), empty(), empty(),
        empty(), empty(), empty(), empty(), empty(), empty(), empty(), empty(),
        empty(), empty(), empty(), empty(), empty(), empty(), empty(), empty(),
        pawn_w(), pawn_w(), pawn_w(), pawn_w(), pawn_w(), pawn_w(), pawn_w(), pawn_w(),
        rook_w(), knight_w(), bishop_w(), queen_w(), king_w(), bishop_w(), knight_w(), rook_w()
      ] |> Stream.with_index()
      |> Stream.reject(fn {what, _at} -> what == empty() end)
      |> Stream.map(fn {what, at} -> {at, what} end)
      |> Enum.into(%{})
    # end
  end

  def compress(l), do: :erlang.list_to_tuple(l) #for f <- l, do: <<f::8>>, into: <<>>

  # def kingpos_b(bin), do: bin |> :binary.match(<<@king_b :: 8>>) |> elem(0)
  # def kingpos_w(bin), do: bin |> :binary.match(<<@king_w :: 8>>) |> elem(0)

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
    [empty()] |> Stream.cycle |> Enum.take(n - 48)
  end
  def map(?r), do: rook_b()
  def map(?n), do: knight_b()
  def map(?b), do: bishop_b()
  def map(?q), do: queen_b()
  def map(?k), do: king_b()
  def map(?p), do: pawn_b()

  def map(?R), do: rook_w()
  def map(?N), do: knight_w()
  def map(?B), do: bishop_w()
  def map(?Q), do: queen_w()
  def map(?K), do: king_w()
  def map(?P), do: pawn_w()

  def map(f), do: raise "Cannot map #{IO.inspect(f)}"

  def cannot_move?(%S{} = b) do
    gen_moves(b)
    #|> Stream.map(fn m -> apply(b, m) end)
    #|> Stream.reject(fn r -> not r.valid end)
    |> Enum.empty?
  end

  def evaluate(%S{white_to_play: wtp} = board) do
    case cannot_move?(board) do
      true ->
        if checked?(board, wtp), do: - Tool.rw({:king, wtp}), else: 0.0
      false -> board.raw_value
    end
  end

  defimpl Gchess.Boards.Fun do
    def get_chm_and_color(target, n), do: @for.get(target, n)
    def getmany_chm_and_color(target, enum), do: enum |> Enum.map(fn n -> @for.get(target, n) end)
    def white_to_play?(target), do: target.white_to_play
    def kingpos_b(target), do: target.king_black
    def kinkpos_w(target), do: target.king_white
    def ep_field(target), do: target.ep_field
    def castle(target), do: target.castle
    def genraw_moves(target, fig, n), do: @for.genraw_moves(target, fig, n)
    def set_wtp(target, white_to_play), do: @for.set_wtp(target, white_to_play)
    def are_empty?(target, enum), do: enum |> Enum.all?(fn n -> @for.empty?(@for.get(target, n)) end) # empty()!

    def is_hit?(target, n, by_white), do: @for.is_hit?(target, n, by_white)
    def is_any_hit?(target, enum, by_white), do: enum |> Enum.any?(fn t -> @for.is_hit?(target, t, by_white) end)

    def gen_moves(target), do: @for.gen_moves(target)
    def apply(target, move), do: @for.apply(target, move)
    def evaluate(target), do: @for.evaluate(target)

    def clear(target, at), do: @for.clear(target, at)
    def checked?(target, wtp), do: @for.checked?(target, wtp)
  end
  # defimpl Area.Shape.Fun, for: P do
  #   def area(target), do: target.area  # @for.min_x(target)
  #   def cog(target), do: target.cog  # @for.max_x(target)
  #   def inside?(target, point), do: target.inside?.(point)
  # end
end # module

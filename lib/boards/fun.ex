defprotocol Gchess.Boards.Fun do
  def get_chm_and_color(target, n)
  def getmany_chm_and_color(target, enum)
  def white_to_play?(target)
  def kingpos_b(target)
  def kinkpos_w(target)
  def ep_field(target)
  def castle(target)
  def genraw_moves(target, fig, n)
  def set_wtp(target, white_to_play)
  def are_empty?(target, enum)

  def checked?(target, wtp)
  def is_hit?(target, n, by_white)
  def is_any_hit?(target, enum, by_white)
  def gen_moves(target)
  def apply(target, move)

  def evaluate(target)
  def clear(target, at)
end

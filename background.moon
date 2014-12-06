
class Star extends PixelParticle

import random from love.math

class StarField extends Box
  default_count: 100

  new: (...) =>
    super ...
    @stars = DrawList!
    @prepopulate!

  prepopulate: =>
    for i=1,@default_count
      x = random @x, @x + @w
      y = random @y, @y + @h
      @stars\add with Star x, y
        .a = random 140, 255

  update: (dt) =>

  draw: =>
    @stars\draw!


{:StarField, :Star}


class Star extends PixelParticle

import random, randomNormal from love.math

class StarField extends Box
  default_count: 100
  base_speed: 20
  max_twinkle: 20
  twinkle_count: 0

  new: (@world) =>
    super @world.stage_extent\unpack!
    @entered = {}

    @stars = DrawList!
    @seqs = DrawList!
    @prepopulate!

  prepopulate: =>
    for i=1,@default_count
      x = random @x, @x + @w
      y = random @y, @y + @h

      @stars\add with Star x, y
        .speed = randomNormal! * 5
        .a = random(20, 200) / 255

  update: (dt) =>
    @seqs\update dt
    world_offset = @world.stage_extent.w * @world.stage_speed
    for star in *@stars
      @update_star star, dt, world_offset

  update_star: (star, dt, world_offset) =>
    star.x -= (world_offset + (@base_speed + star.speed)) * dt

    if star.x > @x + @w
      star.x -= @w

    if star.x < @x
      star.x += @w

    return if @twinkle_count >= @max_twinkle
    return if star.twinkle
    return if star.a > 0.8
    return if random! > 0.01

    @twinkle_count += 1

    star.twinkle = @seqs\add Sequence ->
      before = star.a

      tween star, 0.2, a: 1
      tween star, 0.2, a: before

      star.twinkle = nil
      @twinkle_count -= 1

  draw: =>
    COLOR\pusha 200
    @stars\draw!
    COLOR\pop!

{:StarField, :Star}

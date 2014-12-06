{graphics: g} = love

class Bullet extends Entity
  w: 5
  h: 5
  speed: 200

  new: (...) =>
    super ...
    @vel[1] = @speed

  color: { 0, 255, 100 }

  update: (dt, world) =>
    super dt, world
    world.stage_extent\touches_box @

  draw: =>
    super @color

class Player extends Entity
  color: {255, 255, 255}
  is_player: true
  speed: 100

  w: 10
  h: 5

  new: (...) =>
    super ...
    @seqs = DrawList!

  update: (dt, @world) =>
    dir = CONTROLLER\movement_vector!
    move = dir * (dt * @speed)
    dx, dy = unpack move

    @fit_move dx, dy, @world
    @seqs\update dt

    if CONTROLLER\is_down "shoot"
      @shoot!

    true

  shoot: =>
    return if @shoot_timer
    x = @x + @w / 2 - Bullet.w / 2
    y = @y + @h / 2 - Bullet.h / 2

    @world.bullets\add Bullet x,y

    @shoot_timer = @seqs\add Sequence ->
      wait 0.1
      print "ready"
      @shoot_timer = nil

  draw: =>
    g.polygon "line",
      @x, @y - @h / 2,
      @x + @w * 1.5, @y + @h / 2,
      @x, @y + @h + @h / 2

    -- super {255,100,100,100}


{:Player}

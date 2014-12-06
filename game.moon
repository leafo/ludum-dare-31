
graphics_err_msg = table.concat {
  "Your graphics card doesn't support this game."
  "Leave a comment on Ludum Dare site and I'll code a workaround."
  "Otherwise you'll have to user another computer."
}, "\n"

{graphics: g} = love

class Enemy extends Entity
  is_enemy: true
  color: { 255, 100, 100 }

  new: (...) =>
    super ...
    @alive = true

  update: (dt) =>
    @alive

  draw: =>
    super @color

  take_hit: (thing, world) =>
    @alive = false
    thing.alive = false
    print "enemy taking hit"

class Bullet extends Entity
  w: 5
  h: 5
  speed: 200

  new: (...) =>
    super ...
    @vel[1] = @speed

  color: { 0, 255, 100 }

  update: (...) =>
    super ...
    true

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

    super {255,100,100,100}

class World
  top: 0
  bottom: 200

  stage_height: 80

  mousepressed: (x, y, button) =>
    x, y = @viewport\unproject x, y
    @entities\add Enemy x, y

  calculate: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale

    x1, y1, x2, y2 = @viewport\unpack2!
    x1 += @stage_height
    y1 += @stage_height
    x2 -= @stage_height
    y2 -= @stage_height

    @hud_box = Box x1, y1, x2 - x1, y2 - y1
    @stage_extent = Box 0, 0, (@viewport.w + @viewport.h ) * 2, @stage_height
    assert love.graphics.isSupported("npot"), graphics_err_msg

    print @stage_extent
    @stage_canvas = g.newCanvas @stage_extent.w, @stage_extent.h
    @stage_canvas\setFilter "nearest", "nearest"

    @top_quad = g.newQuad 0, 0, @viewport.w, @stage_height,
      @stage_canvas\getDimensions!

    @right_quad = g.newQuad @viewport.w, 0, @viewport.h, @stage_height,
      @stage_canvas\getDimensions!

    @bottom_quad = g.newQuad @viewport.w + @viewport.h, 0, @viewport.w, @stage_height,
      @stage_canvas\getDimensions!

    @left_quad = g.newQuad @viewport.w * 2 + @viewport.h, 0, @viewport.h, @stage_height,
      @stage_canvas\getDimensions!

  new: =>
    @calculate!

    @entities = DrawList!
    @bullets = DrawList!

    @player = Player 10, 10
    @collider = UniformGrid!
    @seqs = DrawList!

    @entities\add @player

  draw: =>
    g.setCanvas @stage_canvas

    @stage_canvas\clear 10, 13, 20
    @entities\draw!
    @bullets\draw!
    g.setCanvas!

    @viewport\apply!

    @hud_box\draw {0,0,0, 100}

    @viewport\pop!

    for i, quad in ipairs {@top_quad, @right_quad, @bottom_quad, @left_quad}
      y = (10 + @stage_height) * i
      g.draw @stage_canvas, quad, 10, y

  update: (dt) =>
    @entities\update dt, @
    @bullets\update dt, @
    @seqs\update dt, @

    @collider\clear!
    for e in *@entities
      continue unless e.alive
      continue unless e.w -- is a box
      @collider\add e


    -- see if bullets hitting anything
    for b in *@bullets
      continue unless b.alive
      for thing in *@collider\get_touching b
        if thing.take_hit
          thing\take_hit b, @

    @viewport\update dt

  collides: => false

{ :World }

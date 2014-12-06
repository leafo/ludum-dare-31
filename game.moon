
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

  mousepressed: (x, y, button) =>
    x, y = @viewport\unproject x, y
    @entities\add Enemy x, y

  new: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale

    @entities = DrawList!
    @bullets = DrawList!

    @player = Player 10, 10
    @collider = UniformGrid!
    @seqs = DrawList!

    @entities\add @player

  draw: =>
    @viewport\apply!
    love.graphics.print "hello world", 10, 10

    @entities\draw!
    @bullets\draw!

    @viewport\pop!

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

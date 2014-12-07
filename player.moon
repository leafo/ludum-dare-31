{graphics: g} = love

class BulletHitParticle extends ImageParticle
  w: 16
  h: 16
  quad: 2

  lazy sprite: => Spriter "images/sprites.png", 16, 16

class BulletHitEmitter extends Emitter
  new: (@dir=Vec2d(0, -1), ...) =>
    super ...

  make_particle: =>
    with BulletHitParticle @x, @y
      .vel = (@dir * 100)\random_heading(80)
      .accel = Vec2d(0, 300)

class Bullet extends Entity
  is_bullet: true

  w: 5
  h: 5
  speed: 200

  ox: 7
  oy: 7

  lazy sprite: => Spriter "images/sprites.png", 16, 16

  new: (@life, ...) =>
    super ...
    @vel[1] = @speed

  color: { 0, 255, 100 }

  take_hit: (thing, world) =>
    dir = (Vec2d(@center!) - Vec2d(thing\center!))\normalized!


    world.particles\add BulletHitEmitter dir, world, @center!

  update: (dt, world) =>
    super dt, world
    world.stage_extent\touches_box @
    @life -= dt
    alive = @life > 0

    alive

  draw: =>
    @sprite\draw 1, @x - @ox, @y - @oy

class Option extends Entity

class Player extends Entity
  color: {255, 255, 255}
  is_player: true
  speed: 100

  max_upgrades: {
    speed: 3
    distance: 3
    option: 4
    shield: 1
  }

  upgrades: {
    speed: 0
    distance: 0
    option: 0
    shield: 0
    boom: 0
  }

  w: 10
  h: 5

  new: (...) =>
    super ...
    @seqs = DrawList!

  bullet_life: =>
    0.4

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

    @world.bullets\add Bullet @bullet_life!, x,y

    @shoot_timer = @seqs\add Sequence ->
      wait 0.3
      @shoot_timer = nil

  draw: =>
    g.polygon "line",
      @x, @y - @h / 2,
      @x + @w * 1.5, @y + @h / 2,
      @x, @y + @h + @h / 2

    -- super {255,100,100,100}

{:Player}

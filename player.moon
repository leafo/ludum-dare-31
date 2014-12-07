{graphics: g} = love

class Powerup extends Entity
  mixin HasEffects
  lazy sprite: => Spriter "images/sprites.png", 16, 16
  w: 13
  h: 13
  speed: 10

  new: (...) =>
    super ...
    @anim = @sprite\seq {3,5}, 0.2
    @vel = Vec2d(-@speed, 0)

  take_hit: (thing) =>
    return if @dying
    if thing == @world.player
      @dying = true
      @world.player\collect_powerup powerup
      @effects\add BlowOutEffect 0.2, -> @alive = false

  update: (dt, @world) =>
    @move unpack dt * @vel
    @anim\update dt
    @alive and @x > -@w

  draw: =>
    oy = 2 * math.sin(5 * love.timer.getTime!)
    blend = g.getBlendMode!
    g.setBlendMode "additive"
    @anim\draw @x - 2, @y - 2 + oy
    g.setBlendMode blend

    if DEBUG
      super {255, 100,100, 100}

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
      .accel = -1.1 * .vel

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

  on_stuck: =>
    @alive = false

  color: { 0, 255, 100 }

  take_hit: (thing, world) =>
    dir = (Vec2d(@center!) - Vec2d(thing\center!))\normalized!
    world.particles\add BulletHitEmitter dir, world, @center!
    @alive = false

  update: (dt, world) =>
    super dt, world
    world.stage_extent\touches_box @
    @life -= dt
    alive = @life > 0

    alive

  draw: =>
    @sprite\draw 1, @x - @ox, @y - @oy

class Option extends Entity
  @locations: {
    Vec2d 0, -12
    Vec2d 0, 12

    Vec2d -5, -24
    Vec2d -5, 24
  }

  radius: 4
  drot: 1
  rot: 0

  new: (@ship, @position, ...) =>
    super ...
    @seqs = DrawList!

  update: (dt, @world) =>
    tx, ty = unpack Vec2d(@ship\center!) + @position
    tx -= @w/2
    ty -= @w/2

    @x = smooth_approach(@x, tx, dt * 10)
    @y = smooth_approach(@y, ty, dt * 10)

    @seqs\update dt
    true

  shoot: =>
    return if @shoot_timer
    x = @x + @w / 2 - Bullet.w / 2
    y = @y + @h / 2 - Bullet.h / 2

    @world.bullets\add Bullet @ship\bullet_life!, x,y

    @shoot_timer = @seqs\add Sequence ->
      wait @ship\bullet_rate!
      @shoot_timer = nil

  draw: =>
    g.push!
    g.translate @center!

    g.circle "line", 0, 0, @radius, 5
    g.pop!

class Player extends Entity
  mixin HasEffects

  color: {255, 255, 255}
  is_player: true
  speed: 60
  shielded: true

  w: 10
  h: 5

  max_upgrades: {
    speed: 3
    distance: 3
    shot: 3
    option: 4
    shield: 1
    boom: 1
  }

  new: (...) =>
    super ...
    @seqs = DrawList!
    @options = DrawList!

    @upgrades = {
      speed: 0
      distance: 0
      shot: 0
      option: 0
      shield: 0
      boom: 0
    }

  bullet_life: =>
    0.4 + 0.4 * @upgrades.distance * @upgrades.distance

  bullet_rate: =>
    0.3 / math.pow(1.5, @upgrades.shot)

  collect_powerup: (powerup) =>
    @world.hud\add_point!

  add_option: =>
    i = #@options + 1
    position = Option.locations[i]
    return unless position
    @options\add Option @, position, @center!

  die: =>
    return if @dying
    @dying = true
    @effects\add BlowOutEffect 0.8, ->
      @world\end_anim!
      @alive = false

  update: (dt, @world) =>
    unless @dying
      dir = CONTROLLER\movement_vector!
      move = dir * (dt * (@speed + @upgrades.speed * 25))
      dx, dy = unpack move

      @fit_move dx, dy, @world

      if CONTROLLER\is_down "shoot"
        @shoot!

    @seqs\update dt
    @options\update dt, @world

    @alive

  shoot: =>
    for option in *@options
      option\shoot!

    return if @shoot_timer
    x = @x + @w / 2 - Bullet.w / 2
    y = @y + @h / 2 - Bullet.h / 2

    @world.bullets\add Bullet @bullet_life!, x,y

    @shoot_timer = @seqs\add Sequence ->
      wait @bullet_rate!
      @shoot_timer = nil


  draw_ship_origin: =>
    x = -@w/2
    y = -@h/2

    g.polygon "line",
      x, y - @h / 2,
      x + @w * 1.5, y + @h / 2,
      x, y + @h + @h / 2

  draw: =>
    g.polygon "line",
      @x, @y - @h / 2,
      @x + @w * 1.5, @y + @h / 2,
      @x, @y + @h + @h / 2

    if @shielded
      for i=0,1
        t = love.timer.getTime! + i * 0.5
        t = t - math.floor(t)

        COLOR\push 99,254,244, (1 - t) * 255

        g.push!
        g.translate @center!
        g.scale 1 + t* 1.5, 1 + t * 1.5
        @draw_ship_origin!
        g.pop!

        COLOR\pop!

    @options\draw!

    if DEBUG
      super {255,0,0,100}

  upgrade: (what) =>
    error "BOOM" if what == "boom"

    if @upgrades[what] + 1 > @max_upgrades[what]
      return false

    @upgrades[what] += 1
    is_max = @upgrades[what] == @max_upgrades[what]

    switch what
      when "option"
        @add_option!

    button = @world.hud\find_button what
    button\set_level @upgrades[what], is_max
    true


{ :Player, :Powerup }

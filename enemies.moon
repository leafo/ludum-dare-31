
{graphics: g} = love

import randomNormal from love.math

class ExplosionParticle extends ImageParticle
  life: 0.2
  w: 16
  h: 16
  lazy sprite: => Spriter "images/sprites.png", 16, 16
  quad: 4

class ExplosionEmitter extends Emitter
  count: 10
  make_particle: =>
    with ExplosionParticle @x, @y
      .vel = Vec2d(0, -60)\random_heading(360)
      .scale = 1 + randomNormal! / 2
      .accel = Vec2d(0, 200 * randomNormal!)

class Enemy extends Entity
  mixin HasEffects

  is_enemy: true
  core_color: { 255, 100, 100 }
  is_powered: false
  score: 37

  radius: 7
  inner_radius: 3

  speed: 10

  w: 10
  h: 10

  new: (...) =>
    super ...
    @alive = true
    @vel = Vec2d -@speed, 0
    @effects = EffectList!

    @effects\add PopinEffect 0.2
    @effects\add FadeInEffect 0.2

  update: (dt, @world) =>
    @move unpack @vel * dt
    @alive = false if @x < -100
    @alive

  draw: =>
    t = love.timer.getTime!
    if @is_powered
      t = t * 2

    cx, cy = @center!

    if @is_powered
      g.push!
      g.translate cx, cy
      scale = 1.5 + math.sin(t * 2) / 2
      g.scale scale, scale
      g.rotate -t
      g.translate -cx, -cy

    COLOR\push @core_color
    g.rectangle "fill", cx - @inner_radius / 2, cy - @inner_radius / 2,
      @inner_radius, @inner_radius
    COLOR\pop!

    if @is_powered
      g.pop!

    x, y = @center!

    g.push!
    g.translate x,y
    g.rotate t
    g.circle "line", 0, 0, @radius, 6
    g.pop!

    if DEBUG
      super {255,0,0, 100}

  die: =>
    @world.hud\add_score @score
    @dying = true
    @world.particles\add ExplosionEmitter @world, @center!
    @effects\add BlowOutEffect 0.2, -> @alive = false

  take_hit: (thing, world) =>
    return if @dying
    @die!
    if thing.is_bullet
      thing.take_hit and thing\take_hit @, world

class Spawner extends Sequence
  count: 10

  new: (@world, x, y) =>
    super ->
      for i=1,10
        enemy = Enemy x + i * 20, y + 20 * math.sin(i) / 2
        if i == 10
          enemy.is_powered = true

        @world.entities\add enemy
        wait 0.05

{ :Enemy, :Spawner }

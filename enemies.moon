
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
  is_enemy: true
  core_color: { 255, 100, 100 }
  is_powered: true

  radius: 7
  inner_radius: 3

  w: 10
  h: 10

  new: (...) =>
    super ...
    @alive = true

  update: (dt) =>
    @alive

  draw: =>
    t = love.timer.getTime!
    if @is_powered
      t = t * 2

    cx, cy = @center!

    if @is_powered
      g.push!
      g.translate cx, cy
      scale = 1 + math.sin(t * 2) / 3
      g.scale scale, scale
      g.rotate -t
      g.translate -cx, -cy

    -- super @core_color
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

  take_hit: (thing, world) =>
    @alive = false
    if thing.is_bullet
      thing.take_hit and thing\take_hit @, world


    thing.alive = false
    world.particles\add ExplosionEmitter world, @center!
    print "enemy taking hit"

{ :Enemy }

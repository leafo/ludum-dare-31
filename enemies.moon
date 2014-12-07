
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
    -- hack for effects mixin
    @draw_inner!

  draw_inner: =>
    error "replace me"

  die: =>
    @world.hud\add_score @score
    @dying = true
    @world.particles\add ExplosionEmitter @world, @center!
    @effects\add BlowOutEffect 0.2, -> @alive = false
    if @is_powered
      import Powerup from require "player"
      @world.entities\add Powerup @center!

  take_hit: (thing, world) =>
    return if @dying
    @die!
    if thing.is_bullet
      thing.take_hit and thing\take_hit @, world

  draw_hitbox: =>
    return unless DEBUG
    COLOR\push 255,0,0, 100
    g.rectangle "fill", @unpack!
    COLOR\pop!

class Drone extends Enemy
  draw_inner: =>
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

    @draw_hitbox!


class Shooter extends Enemy
  update: (...) =>
    @vel = Vec2d 0,0
    super ...

  draw_inner: =>
    bar_l = 15
    bar_w = 5

    ox = bar_l/2
    oy = (bar_w + 2)

    g.push!
    cx, cy = @center!
    cx -= 0.5
    cy -= 0.5
    g.translate cx, cy

    g.rotate love.timer.getTime!
    g.translate -ox, -oy

    g.rectangle "line", 0, 0, bar_l, bar_w
    g.rectangle "line", 0, bar_w + 3, bar_l, bar_w

    g.pop!

    @draw_hitbox!

class Spawner extends Sequence
  enemy_types: {
  }

  active: false

  new: (...) =>
    super ...
    @range = Box 0,0, 200, 80
    @range.x = @x - @range.w

  draw: =>
    if DEBUG and @world
      COLOR\push 0,100,255
      g.setPointSize 5
      g.point @x - @world.map.scroll_offset, @y
      g.rectangle "line", @range\unpack!
      COLOR\pop!

  update: (dt, @world) =>
    @range.x = @x - @range.w - world.map.scroll_offset

    if not @active
      for touching in *world.collider\get_touching @range
        continue unless touching.is_player
        @active = true

    if @active
      return super dt, world

    true

class ChainSpawner extends Spawner
  count: 5
  spacing: 23

  new: (@world, @x, @y) =>
    enemy_cls = Drone

    super ->
      time_offset = love.math.random! * math.pi * 2
      for i=0,@count - 1
        ox = enemy_cls.w / 2
        oy = enemy_cls.h / 2

        enemy = enemy_cls @x + i * @spacing - ox,
          @y + @spacing * math.sin(i * math.pi / 5 + time_offset) / 2 - oy

        if i == @count - 1
          enemy.is_powered = true

        @world.entities\add enemy
        wait 0.1

class SingleSpawner extends Spawner
  new: (@world, @x, @y, @obj) =>
    super ->
      @add_enemy!
      wait 0.1 -- lame hack

  add_enemy: =>
    enemy_cls = Drone
    @world.entities\add enemy_cls @x, @y

{
  :Enemy,
  :Drone, :Shooter
  :Spawner, :ChainSpawner, :SingleSpawner
}

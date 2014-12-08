
{graphics: g} = love

import randomNormal from love.math

import ExplosionEmitter from require "emitters"

class EnemyBullet extends Entity
  is_enemy_bullet: true

  w: 4
  h: 4
  speed: 200

  ox: 6
  oy: 6

  lazy sprite: => Spriter "images/sprites.png", 16, 16

  new: (@x,@y, dir=Vec2d(-1, 0)) =>
    @vel = @speed * dir

  on_stuck: =>
    @alive = false

  draw: =>
    @sprite\draw 6, @x - @ox, @y - @oy
    super {0, 100, 255}

  update: (dt, world)=>
    super dt, world
    @alive

class Enemy extends Entity
  mixin HasEffects

  is_enemy: true
  core_color: { 255, 50, 50 }
  is_powered: false

  score: 37

  radius: 7
  inner_radius: 3

  speed: 10

  w: 10
  h: 10

  time: 0

  new: (...) =>
    super ...
    @alive = true
    @vel = Vec2d -@speed, 0

    @seqs = DrawList!
    @effects = EffectList!
    @effects\add PopinEffect 0.2
    @effects\add FadeInEffect 0.2

    if @ai = @make_ai!
      @seqs\add @ai

  make_ai: =>

  update: (dt, @world) =>
    @move unpack @vel * dt
    @time += dt * (@is_powered and 2 or 1)
    @seqs\update dt

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
    AUDIO\play "enemy_die"
    if @is_powered
      import Powerup from require "player"
      @world.entities\add Powerup @center!

  take_hit: (thing, world) =>
    return if @dying

    if thing.is_player
      thing\die!

    if thing.is_bullet
      @die!
      thing.take_hit and thing\take_hit @, world

  draw_hitbox: =>
    return unless DEBUG
    COLOR\push 255,0,0, 100
    g.rectangle "fill", @unpack!
    COLOR\pop!

  draw_core: =>
    cx, cy = @center!

    if @is_powered
      g.push!
      g.translate cx, cy
      scale = 1.5 + math.sin(@time * 2) / 2
      g.scale scale, scale
      g.rotate -@time
      g.translate -cx, -cy

    COLOR\push @core_color
    g.rectangle "fill", cx - @inner_radius / 2, cy - @inner_radius / 2,
      @inner_radius, @inner_radius
    COLOR\pop!

    if @is_powered
      g.pop!

  make_ai: =>
    do return
    Sequence ->
      wait 2 + randomNormal!
      if love.math.random! > 0.5
        -- @shoot!
        @shoot_sweep!
      again!

  -- points to player
  shoot_dir: =>
    target = Vec2d @world.player\center!
    src = Vec2d @center!
    (target - src)\normalized!

  add_bullet: (...) =>
    AUDIO\play "enemy_shoot"
    cx, cy = @center!
    @world.bullets\add EnemyBullet cx, cy, ...

  shoot: =>
    @add_bullet @shoot_dir!

  shoot_sweep: (bullets=5, degs=40, delay=0.2) =>
    rads = math.rad degs

    @shooting = @seqs\add Sequence ->
      dir = @shoot_dir!
      half = rads/2
      spin_dir = pick_one(-1, 1)
      spin_step = rads/bullets
      dir = dir\rotate -spin_dir * half

      for i=1,bullets
        @add_bullet dir
        dir = dir\rotate spin_step * spin_dir
        wait delay

class Drone extends Enemy
  draw_inner: =>
    @draw_core!

    x, y = @center!
    g.push!
    g.translate x,y
    g.rotate @time
    g.circle "line", 0, 0, @radius, 6
    g.pop!

    @draw_hitbox!

class Shooter extends Enemy
  draw_inner: =>
    bar_l = 15
    bar_w = 5

    @draw_core!

    ox = bar_l/2
    oy = (bar_w + 2)

    g.push!
    cx, cy = @center!
    cx -= 0.5
    cy -= 0.5
    g.translate cx, cy

    g.rotate @time
    g.translate -ox, -oy

    g.rectangle "line", 0, 0, bar_l, bar_w
    g.rectangle "line", 0, bar_w + 3, bar_l, bar_w

    g.pop!

    @draw_hitbox!

class Charger extends Enemy
  aggression: 1
  time: 0

  radius: 4

  update: (dt, ...) =>
    super dt, ...

  draw_inner: =>
    @draw_core!

    g.push!
    cx, cy = @center!
    cx -= 0.5
    cy -= 0.5
    g.translate cx, cy
    g.rotate @time

    pos = Vec2d(0, -1) * (@radius * 1.5)
    for i=1,3
      g.circle "line", pos[1], pos[2], @radius, 5
      pos = pos\rotate math.pi*2/3

    g.pop!

    @draw_hitbox!

class Boss extends Enemy
  is_powered: true
  open: 0 -- from 0 to 1, opens mouth for when shooting

  update: (dt, ...) =>
    @vel = Vec2d 0,0
    super dt, ...

  draw_inner: =>
    @draw_core!

    @draw_hitbox!

    g.push!
    g.translate @center!

    oy = 5
    ox = 5
    len = 30
    wing = 12

    rot = math.sin(@time) / 10 + @open * 0.6

    -- top
    g.push!
    g.rotate rot
    g.polygon "line", -len + ox, -oy,
      ox, -oy - wing,
      ox, -oy
    g.pop!

    -- bottom
    g.push!
    g.rotate -rot
    g.polygon "line", -len + ox, oy,
      ox, oy + wing,
      ox, oy

    g.pop!
    g.pop!

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
      g.point @x, @y
      g.rectangle "line", @range\unpack!
      COLOR\pop!

  update: (dt, @world) =>
    @range.x = @x - @range.w

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
  :Enemy, :EnemyBullet
  :Drone, :Shooter, :Charger, :Boss
  :Spawner, :ChainSpawner, :SingleSpawner
}

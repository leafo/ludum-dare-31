
graphics_err_msg = table.concat {
  "Your graphics card doesn't support this game."
  "Leave a comment on Ludum Dare site and I'll code a workaround."
  "Otherwise you'll have to user another computer."
}, "\n"

{graphics: g} = love

import StarField from require "background"
import Player, Poweup from require "player"
import Hud from require "hud"
import Spawner from require "enemies"

import random, randomNormal from love.math

PAUSED = false

class EdgeParticle extends ImageParticle
  w: 16
  h: 16

  lazy sprite: => Spriter "images/sprites.png", 16, 16
  life: 0.5
  quad: 0

class Edge extends Box
  direction: Vec2d 1,0
  color: {168, 219, 255}
  speed: 50

  new: (...) =>
    super ...
    @seq = Sequence ->
      for i=1,2
        yoffset = random 0, @h
        @world.particles\add with EdgeParticle @x, @y + yoffset, @direction * @speed
          .vel = .vel + Vec2d randomNormal! * 10, 0
          .a = random(70,100) / 100
          .spin = random!
          .dspin = randomNormal! * 2
          .scale = 1 + randomNormal! / 2

      wait random! * 0.1 + 0.05
      again!

  draw: =>
    super @color

  update: (dt, @world) =>
    @seq\update dt
    true

class World
  top: 0
  bottom: 200
  time: 0

  stage_height: 80
  stage_speed: 0.05

  mousepressed: (x, y, button) =>
    @player\add_option!

  calculate: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale

    x1, y1, x2, y2 = @viewport\unpack2!
    x1 += @stage_height
    y1 += @stage_height
    x2 -= @stage_height
    y2 -= @stage_height

    @hud = Hud x1, y1, x2 - x1, y2 - y1
    @stage_extent = Box 0, 0, (@viewport.w + @viewport.h ) * 2, @stage_height

    assert love.graphics.isSupported("npot"), graphics_err_msg

    @stage_canvas = g.newCanvas @stage_extent.w, @stage_extent.h
    @stage_canvas\setFilter "nearest", "nearest"

    @top_quad = g.newQuad @stage_height, 0,
      @viewport.w - @stage_height * 2, @stage_height,
      @stage_canvas\getDimensions!

    @right_quad = g.newQuad @viewport.w + @stage_height, 0,
      @viewport.h - @stage_height *2 , @stage_height,
      @stage_canvas\getDimensions!

    @bottom_quad = g.newQuad @viewport.w + @viewport.h + @stage_height, 0,
      @viewport.w - @stage_height * 2, @stage_height,
      @stage_canvas\getDimensions!

    @left_quad = g.newQuad @viewport.w * 2 + @viewport.h + @stage_height, 0,
      @viewport.h - @stage_height * 2, @stage_height,
      @stage_canvas\getDimensions!

    -- buffer holds time adjusted stage canvas
    @stage_buffer = g.newCanvas @stage_extent.w, @stage_extent.h
    @stage_buffer\setFilter "nearest", "nearest"

    @edge_left = Edge 0, 0, 5, @stage_height

    @edge_right = with Edge @stage_extent.w - 5, 0, 5, @stage_height
      .direction = Vec2d -1, 0

    -- create mesh

    -- top
    top_left = Box(0, 0, @stage_height, @stage_height) / @stage_extent
    top_right = Box(@viewport.w - @stage_height, 0, @stage_height, @stage_height) / @stage_extent

    -- right
    right_left = Box(@viewport.w, 0, @stage_height, @stage_height) / @stage_extent
    right_right = Box(@viewport.w + @viewport.h - @stage_height, 0, @stage_height, @stage_height) / @stage_extent

    -- bottom
    bottom_left = Box(@viewport.w + @viewport.h, 0, @stage_height, @stage_height) / @stage_extent
    bottom_right = Box(@viewport.w * 2 + @viewport.h - @stage_height, 0, @stage_height, @stage_height) / @stage_extent

    -- left
    left_left = Box(@viewport.w * 2 + @viewport.h, 0, @stage_height, @stage_height) / @stage_extent
    left_right = Box(@viewport.w * 2 + @viewport.h * 2 - @stage_height, 0, @stage_height, @stage_height) / @stage_extent

    divs = 3

    @top_left_mesh = @create_corner_mesh divs, true, top_left\unpack2!
    @top_right_mesh = @create_corner_mesh divs, false, top_right\unpack2!

    @right_left_mesh = @create_corner_mesh divs, true, right_left\unpack2!
    @right_right_mesh = @create_corner_mesh divs, false, right_right\unpack2!

    @bottom_left_mesh = @create_corner_mesh divs, true, bottom_left\unpack2!
    @bottom_right_mesh = @create_corner_mesh divs, false, bottom_right\unpack2!

    @left_left_mesh = @create_corner_mesh divs, true, left_left\unpack2!
    @left_right_mesh = @create_corner_mesh divs, false, left_right\unpack2!

  draw_corner_mesh: (mesh, x, y) =>
    g.push!
    g.translate x,y
    g.scale @stage_height, @stage_height
    mesh\setTexture @stage_buffer
    g.draw mesh, 0, 0
    g.pop!

  create_corner_mesh: (divisions=3, left=true, s1=0, t1=0, s2=1, t2=1) =>
    assert divisions > 1
    verts = {}

    ds = s2 - s1
    dt = t2 - t1

    for y=0,divisions
      py = y / divisions

      for x=0,divisions
        px = x / divisions
        vx = if left
          px * (1 - py) + py
        else
          px * (1 - py)

        s = s1 + px * ds
        t = t1 + py * dt

        table.insert verts, {
          vx, py
          s, t
          255,255,255
        }

    mesh = g.newMesh verts, nil, "triangles"
    vertex_map = {}

    ww = divisions + 1

    for i=1,mesh\getVertexCount! - ww
      continue if i % ww == 0
      table.insert vertex_map, i
      table.insert vertex_map, i + 1
      table.insert vertex_map, i + ww

      table.insert vertex_map, i + 1
      table.insert vertex_map, i + ww
      table.insert vertex_map, i + ww + 1

      nil

    mesh\setVertexMap vertex_map

    mesh

  new: =>
    @hi = imgfy "images/hi.png"
    @hi.tex\setFilter "linear", "linear"

    @calculate!
    @background = StarField @

    @entities = DrawList!
    @particles = DrawList!
    @bullets = DrawList!

    @player = Player 50, @stage_height/3
    @collider = UniformGrid!
    @seqs = DrawList!

    @entities\add @player
    @entities\add @edge_left
    @entities\add @edge_right

    @seqs\add Spawner @, 150, @stage_height / 2

    @entities\add Poweup 100, 50

  draw_stage: =>
    @stage_canvas\clear 10, 13, 20

    @background\draw!
    @entities\draw!
    @bullets\draw!

    blend = g.getBlendMode!
    g.setBlendMode "additive"
    @particles\draw!
    g.setBlendMode blend

  draw_stage_buffer: =>
    @stage_buffer\clear 255, 0,0

    @slice_quad or= g.newQuad 0, 0, 0,0, @stage_buffer\getDimensions!
    offset = @time * @stage_extent.w
    @slice_quad\setViewport 0, 0, @stage_extent.w - offset, @stage_height
    g.draw @stage_canvas, @slice_quad, offset, 0

    @slice_quad\setViewport @stage_extent.w - offset, 0, offset, @stage_height
    g.draw @stage_canvas, @slice_quad, 0, 0

  draw: =>
    -- g.setWireframe true
    g.setCanvas @stage_canvas
    @draw_stage!
    g.setCanvas!

    g.setCanvas @stage_buffer
    @draw_stage_buffer!
    g.setCanvas!

    @viewport\apply!
    @hud\draw!
    canvas = @stage_buffer

    -- top
    g.draw canvas, @top_quad, @stage_height, 0
    @draw_corner_mesh @top_left_mesh, 0,0
    @draw_corner_mesh @top_right_mesh, @viewport.w - @stage_height, 0

    -- right
    g.push!
    g.translate @viewport.w, 0
    g.rotate math.pi / 2

    g.draw canvas, @right_quad, @stage_height,0
    @draw_corner_mesh @right_left_mesh, 0,0
    @draw_corner_mesh @right_right_mesh, @viewport.h - @stage_height, 0

    g.pop!

    -- bottom
    g.push!
    g.translate @viewport.w, @viewport.h
    g.rotate math.pi
    g.draw canvas, @bottom_quad, @stage_height, 0
    @draw_corner_mesh @bottom_left_mesh, 0,0
    @draw_corner_mesh @bottom_right_mesh, @viewport.w - @stage_height, 0
    g.pop!

    -- left
    g.push!
    g.translate 0, @viewport.h
    g.rotate math.pi * 1.5
    g.draw canvas, @left_quad, @stage_height,0

    @draw_corner_mesh @left_left_mesh, 0,0
    @draw_corner_mesh @left_right_mesh, @viewport.h - @stage_height, 0

    g.pop!

    @viewport\pop!

  update: (dt) =>
    return if PAUSED

    @entities\update dt, @
    @bullets\update dt, @
    @particles\update dt, @

    @seqs\update dt, @
    @background\update dt, @
    @hud\update dt

    @time += dt * @stage_speed
    @time -= 1 if @time > 1
    @time = 0

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

    -- see if player hitting anything
    if @player.alive
      for thing in *@collider\get_touching @player
        if thing.take_hit
          thing\take_hit @player, @

    @viewport\update dt

  collides: (thing) =>
    not thing\touches_box @stage_extent

  on_key: (key) =>
    if key == " "
      PAUSED = not PAUSED

{ :World }

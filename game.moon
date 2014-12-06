
graphics_err_msg = table.concat {
  "Your graphics card doesn't support this game."
  "Leave a comment on Ludum Dare site and I'll code a workaround."
  "Otherwise you'll have to user another computer."
}, "\n"

{graphics: g} = love

import StarField from require "background"
import Player from require "player"

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


class World
  top: 0
  bottom: 200
  time: 0

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


    q = g.newQuad 10, 10, 50, 50, 100, 100
    print q\getViewport!

    -- buffer holds time adjusted stage canvas
    @stage_buffer = g.newCanvas @stage_extent.w, @stage_extent.h
    @stage_buffer\setFilter "nearest", "nearest"

  new: =>
    @calculate!
    @background = StarField @stage_extent\unpack!

    @entities = DrawList!
    @bullets = DrawList!

    @player = Player 10, 10
    @collider = UniformGrid!
    @seqs = DrawList!

    @entities\add @player

  draw: =>
    g.setCanvas @stage_canvas

    @stage_canvas\clear 10, 13, 20

    @background\draw!
    @entities\draw!
    @bullets\draw!
    g.setCanvas!


    g.setCanvas @stage_buffer
    @stage_buffer\clear 255, 0,0

    @slice_quad or= g.newQuad 0, 0, 0,0, @stage_buffer\getDimensions!
    offset = @time * @stage_extent.w
    @slice_quad\setViewport 0, 0, @stage_extent.w - offset, @stage_height
    g.draw @stage_canvas, @slice_quad, offset, 0

    @slice_quad\setViewport @stage_extent.w - offset, 0, offset, @stage_height
    g.draw @stage_canvas, @slice_quad, 0, 0

    g.setCanvas!


    @viewport\apply!

    @hud_box\draw {0,0,0, 100}

    @viewport\pop!

    canvas = @stage_buffer
    for i, quad in ipairs {@top_quad, @right_quad, @bottom_quad, @left_quad}
      y = (10 + @stage_height) * i
      g.draw canvas, quad, 10, y

  update: (dt) =>
    @entities\update dt, @
    @bullets\update dt, @
    @seqs\update dt, @

    @time += dt / 10
    @time -= 1 if @time > 1

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

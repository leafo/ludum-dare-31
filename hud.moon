{graphics: g} = love

import VList, HList, Bin, Label from require "lovekit.ui"

class Button extends Box
  state: "disabled"
  alive: true
  padding: 2

  new: (@text, @state) =>
    font = g.getFont!

    @w = 100
    @text_w = font\getWidth(text) + @padding * 2
    @h = font\getHeight! + @padding * 2

  draw: =>
    if @state == "disabled"
      COLOR\pusha 100
    else
      g.push!
      g.translate 1,1
      g.rectangle "fill", @unpack!
      g.pop!

    COLOR\push 40,40,40
    g.rectangle "fill", @unpack!
    COLOR\pop!

    COLOR\push 100,100,100
    g.rectangle "line", @unpack!
    COLOR\pop!

    if @state == "disabled"
      COLOR\push 80, 80, 80

    x = @x + (@w - @text_w) / 2
    g.print @text, x + @padding, @y + @padding

    if @state == "disabled"
      COLOR\pop!

    if @state == "disabled"
      COLOR\pop!

class Hud extends Box
  max_points: 6
  points: 0

  new: (...) =>
    super ...

    @all_buttons = {
      Button "speed"
      Button "distance"
      Button "double"

      Button "option"
      Button "shield"
      Button "boom"
    }

    buttons = VList {
      HList [b for b in *@all_buttons[1,2]]
      HList [b for b in *@all_buttons[3,4]]
      HList [b for b in *@all_buttons[5,]]
    }

    @bin = Bin 0,0, @w,@h, buttons, 0.5, 0.5

  update: (dt) =>
    @bin\update dt

    time = love.timer.getTime! * 5
    @points = math.floor(time) % (@max_points + 1)

    for i, b in ipairs @all_buttons
      b.state = if i == @points
        "active"
      else
        "disabled"

  draw: =>
    g.push!
    g.translate @x, @y
    @bin\draw!
    g.pop!

{ :Hud }

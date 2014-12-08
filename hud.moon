{graphics: g} = love

import VList, HList, Bin, Label from require "lovekit.ui"

class Button extends Box
  state: "disabled"
  alive: true
  padding: 2

  new: (@label, @state) =>
    font = g.getFont!
    @h = font\getHeight! + @padding * 2
    @w = 100
    @set_level 0

  set_level: (level, is_max) =>
    font = g.getFont!
    @text = if is_max
      "#{@label} : max"
    elseif level > 0
      "#{@label} : #{"!"\rep level}"
    else
      @label

    @text_w = font\getWidth(@text) + @padding * 2

  draw: =>
    if @state == "disabled"
      COLOR\pusha 100
    else
      g.push!
      g.translate 1,1
      g.rectangle "fill", @unpack!
      g.pop!

    shade = 40
    if @state == "active"
      time = love.timer.getTime!
      shade += 10 + 10 * math.sin(time * 8)

    COLOR\push shade, shade, shade
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
  padding: 6
  max_points: 6
  points: 0
  score: 0
  display_score: 0
  fade_out: 0

  upgrades: {"speed", "distance", "shot", "option", "shield", "boom"}

  new: (@world, ...) =>
    super ...

    @all_buttons = [Button label for label in *@upgrades]
    @seqs = DrawList!

    buttons = VList {
      HList [b for b in *@all_buttons[1,2]]
      HList [b for b in *@all_buttons[3,4]]
      HList [b for b in *@all_buttons[5,]]
    }

    @bin = Bin 0,0, @w,@h, buttons, 0.5, 0.5
    @score_label = Bin @padding, @padding, @w - @padding*2, @h - @padding*2,
      Label(-> "score: #{math.floor @display_score}"),
      1, 1

    @upgrade_label = Bin @padding, @padding, @w - @padding*2, @h - @padding*2,
      Label(-> "press 'c' upgrade '#{@upgrades[@points]}'"),
      0, 1

    @game_over_label = Bin 0, 0, @w, @h, VList{
      Label "game over"
      Label "press 'x' to try again"
    }, 0.5, 0.5

  add_score: (pts) =>
    @score += pts

  add_point: =>
    @points += 1
    @points = math.min @max_points, @points

  find_button: (name) =>
    for button in *@all_buttons
      if button.label == name
        return button

  update: (dt) =>
    @seqs\update dt
    @bin\update dt
    @score_label\update dt
    @upgrade_label\update dt
    @game_over_label\update dt

    @display_score = smooth_approach @display_score, @score, dt * 10

    if not @world.player.alive and not @game_over
      @game_over = true
      @seqs\add AUDIO\fade_music!

      @seqs\add Sequence ->
        tween @, 1.0, fade_out: 1

    if @game_over
      if CONTROLLER\tapped "confirm"
        @world\restart!
    else
      if @points > 0 and CONTROLLER\tapped "upgrade"
        upgrade = @upgrades[@points]
        if @world.player\upgrade upgrade
          @points = 0
        else
          print "audio BUZZ"

    for i, b in ipairs @all_buttons
      b.state = if i == @points
        "active"
      else
        "disabled"

  draw: =>
    if @fade_out == 0
      @draw_default!
      return

    if @fade_out == 1
      @draw_game_over!
      return

    COLOR\pusha (1 - @fade_out) * 255
    @draw_default!
    COLOR\pop!

    COLOR\pusha (@fade_out) * 255
    @draw_game_over!
    COLOR\pop!


  draw_game_over: =>
    g.push!
    g.translate @x, @y

    @score_label\draw!
    @game_over_label\draw!

    g.pop!

  draw_default: =>
    g.push!
    g.translate @x, @y
    @bin\draw!
    @score_label\draw!

    if @points > 0 and duty_on!
      COLOR\pusha 180
      @upgrade_label\draw!
      COLOR\pop!


    g.pop!

{ :Hud }

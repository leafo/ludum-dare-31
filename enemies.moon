
{graphics: g} = love

class Enemy extends Entity
  is_enemy: true
  core_color: { 255, 100, 100 }
  is_powered: true

  radius: 7
  w: 3
  h: 3

  new: (...) =>
    super ...
    @alive = true

  update: (dt) =>
    @alive

  draw: =>
    t = love.timer.getTime!
    if @is_powered
      t = t * 2

    if @is_powered
      g.push!
      cx, cy = @center!
      g.translate cx, cy
      scale = 1 + math.sin(t * 2) / 3
      g.scale scale, scale
      g.rotate -t
      g.translate -cx, -cy

    super @core_color

    if @is_powered
      g.pop!

    x, y = @center!

    g.push!
    g.translate x,y
    g.rotate t
    g.circle "line", 0, 0, @radius, 6
    g.pop!

  take_hit: (thing, world) =>
    @alive = false
    thing.alive = false
    print "enemy taking hit"

{ :Enemy }

{graphics: g} = love

class ScrollingMap extends TileMap
  speed: 100
  scroll_offset: 0

  draw: (box) =>
    g.push!
    g.translate -@scroll_offset, 0

    adjusted_box = Box box\unpack!
    adjusted_box\move @scroll_offset, 0

    super adjusted_box
    g.pop!

  collides: (thing) =>
    thing = thing.box or thing
    x1, y1, x2, y2 = thing\unpack2!

    x1 += @scroll_offset
    x2 += @scroll_offset
    @player_box = Box x1, y1, x2 - x1 , y2 - y1

    super x1, y1, x2, y2

  update: (dt, @world) =>
    super dt
    @scroll_offset += dt * @speed

{ :ScrollingMap }

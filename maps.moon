{graphics: g} = love

class ScrollingMap extends TileMap
  target_speed: 10
  speed: 0
  scroll_offset: 0

  -- 6
  autotiles: {
    floor: 1 + 6
    floor_border: 1

    ceiling: 2
    ceiling_border: 2 + 6
  }

  autotile: =>
    max_layer = @max_layer

    solid_layer = @layers[max_layer]
    decor_layer = {}

    for i, tile in pairs solid_layer
      x,y = @to_xy i

      -- foor tile
      if fi = @to_i x, y  - 1
        above = solid_layer[fi]
        unless above
          tile.tid = @autotiles.floor
          decor_layer[fi] = {
            tid: @autotiles.floor_border
            layer: 2
          }

      -- ciel tile
      if ci = @to_i x, y  + 1
        below = solid_layer[ci]
        unless below
          tile.tid = @autotiles.ceiling
          decor_layer[ci] = {
            tid: @autotiles.ceiling_border
            layer: 2
          }

    if next decor_layer
      @add_tiles decor_layer

  draw: (box) =>
    g.push!
    g.translate -math.floor(@scroll_offset), 0

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
    @speed = smooth_approach @speed, @target_speed, dt
    @scroll_offset += dt * @speed

{ :ScrollingMap }

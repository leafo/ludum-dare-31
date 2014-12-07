
{graphics: g, :timer} = love

-- only renders parts above a threshold
class GlowShader
  new: (viewport, @scale=2) =>
    @box = viewport\scale 1/@scale
    @canvas = g.newCanvas math.floor(@box.w), math.floor(@box.h)

    @shader = g.newShader @shader!

  shader: -> [[
    float luminance(vec3 rgb) {
      const vec3 w = vec3(0.2125, 0.7154, 0.0721);
      return dot(rgb, w);
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      vec4 c = Texel(texture, texture_coords);
      vec4 final = c * color;
      float l = luminance(final.rgb);

      if (l > 0.4) {
        return vec4(l, l, l, final.a);
      } else {
        return vec4(0,0,0,255);
      }
    }
  ]]

  send: =>

  render: (src_canvas) =>
    g.setCanvas @canvas
    @canvas\clear 0,0,0,0

    g.setShader @shader
    @send!

    g.push!
    g.scale 1/@scale, 1/@scale
    g.draw src_canvas, 0,0
    g.setCanvas!

    g.setShader!
    g.pop!

    g.setCanvas src_canvas
    g.push!
    g.scale @scale, @scale

    blend = g.getBlendMode!
    g.setBlendMode "additive"

    COLOR\push 80,80,80
    g.draw @canvas
    COLOR\pop!

    g.setBlendMode blend

    g.pop!
    g.setCanvas


{ :GlowShader }

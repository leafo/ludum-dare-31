
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


class LutShader
  shader: -> [[
    extern Image lut;

    // from https://github.com/mattdesl/glsl-lut/blob/master/index.glsl
    vec4 lookup(vec4 textureColor, Image lookupTable) {
      float blueColor = textureColor.b * 63.0;

      vec2 quad1;
      quad1.y = floor(floor(blueColor) / 8.0);
      quad1.x = floor(blueColor) - (quad1.y * 8.0);

      vec2 quad2;
      quad2.y = floor(ceil(blueColor) / 8.0);
      quad2.x = ceil(blueColor) - (quad2.y * 8.0);

      vec2 texPos1;
      texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
      texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

      vec2 texPos2;
      texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
      texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

      lowp vec4 newColor1 = Texel(lookupTable, texPos1);
      lowp vec4 newColor2 = Texel(lookupTable, texPos2);

      lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
      return newColor;
    }

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      vec4 c = Texel(texture, texture_coords);
      return lookup(c, lut);
    }
  ]]

  send: =>
    @shader\send "lut", @lookup_image

  new: (@lookup_image) =>
    @shader = g.newShader @shader!

  render: (fn) =>
    g.setShader @shader
    @send!
    fn!
    g.setShader!

{ :GlowShader, :LutShader }

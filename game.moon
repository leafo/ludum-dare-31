
class Game
  new: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale

  draw: =>
    @viewport\apply!
    love.graphics.print "hello world", 10, 10

    @viewport\pop!

  update: (dt) =>

{ :Game }

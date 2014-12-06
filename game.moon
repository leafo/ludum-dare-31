
class Player extends Entity
  color: {255, 255, 255}
  is_player: true

  w: 10
  h: 10

  update: (dt) =>
    true

  draw: =>
    super @color

class Game
  new: =>
    @viewport = EffectViewport scale: GAME_CONFIG.scale
    @entities = DrawList!

    @player = Player 10, 10
    @entities\add @player

  draw: =>
    @viewport\apply!
    love.graphics.print "hello world", 10, 10

    @entities\draw!

    @viewport\pop!

  update: (dt) =>
    @entities\update dt, @

  collides: => false

{ :Game }

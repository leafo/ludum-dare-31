
{graphics: g} = love
import randomNormal from love.math

class ExplosionParticle extends ImageParticle
  life: 0.2
  w: 16
  h: 16
  lazy sprite: => Spriter "images/sprites.png", 16, 16
  quad: 4

class ExplosionEmitter extends Emitter
  count: 10

  get_point: =>
    @x, @y

  make_particle: =>
    x, y = @get_point!
    with ExplosionParticle x, y
      .vel = Vec2d(0, -60)\random_heading(360)
      .scale = 1 + randomNormal! / 2
      .accel = Vec2d(0, 200 * randomNormal!)

class BigExplosionEmitter extends ExplosionEmitter
  spread: 10
  count: 30

  get_point: =>
    @x + randomNormal! * @spread, @y + randomNormal! * @spread / 2


{ :ExplosionEmitter, :BigExplosionEmitter }

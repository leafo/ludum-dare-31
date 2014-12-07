export GAME_CONFIG = {
  scale: 2
  keys: {
    confirm: { "x", " ", joystick: 1 }
    cancel: { "c", joystick: 2 }

    shoot: { "c", "return", joystick: 2 }
    special: { "x", " ", joystick: 1 }

    up: "up"
    down: "down"
    left: "left"
    right: "right"
  }
}

love.conf = (t) ->
  t.window.width = 420 * GAME_CONFIG.scale
  t.window.height = 272 * GAME_CONFIG.scale

  t.title = "shfoefppf"
  t.author = "leafo"

export GAME_CONFIG = {
  scale: 2
  keys: {
    confirm: { "x", " " }
    cancel: "c"

    shoot: { "c", "return" }
    special: { "x", " " }

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

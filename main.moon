require "lovekit.all"

if pcall(-> require"inotify")
  require "lovekit.reloader"

{graphics: g} = love

import World from require "game"

export DEBUG = false

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  fonts = {
    default: load_font "images/font.png",
      [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]
  }

  g.setFont fonts.default

  g.setBackgroundColor 10, 10, 10

  export AUDIO = Audio "sounds"
  AUDIO\preload {
    "bullet_hit_wall"
    "enemy_die"
    "enemy_hit"
    "enemy_shoot"
    "lose_shield"
    "player_die"
    "powerup"
    "shoot"
    "start_game"
    "upgrade"
  }

  export CONTROLLER = Controller GAME_CONFIG.keys, "auto"
  export DISPATCHER = Dispatcher World!
  DISPATCHER.default_transition = FadeTransition
  DISPATCHER\bind love


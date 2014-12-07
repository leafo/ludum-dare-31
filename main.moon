require "lovekit.all"

if pcall(-> require"inotify")
  require "lovekit.reloader"

{graphics: g} = love

import World from require "game"

export DEBUG = true

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  fonts = {
    default: load_font "images/font.png",
      [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]
  }

  g.setFont fonts.default

  g.setBackgroundColor 234, 240, 245
  g.setBackgroundColor 10, 10, 10

  export CONTROLLER = Controller GAME_CONFIG.keys, "auto"
  export DISPATCHER = Dispatcher World!
  DISPATCHER\bind love


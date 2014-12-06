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
  g.setBackgroundColor 13,15,12

  export CONTROLLER = Controller GAME_CONFIG.keys
  export DISPATCHER = Dispatcher World!
  DISPATCHER\bind love


require "lovekit.all"

if pcall(-> require"inotify")
  require "lovekit.reloader"

{graphics: g} = love

export DEBUG = false

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 13,15,12

  export DISPATCHER = Dispatcher Game!
  DISPATCHER\bind love


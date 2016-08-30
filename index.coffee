path = require 'path'

module.exports = (robot) ->
  robot.loadFile(path.resolve(__dirname, 'scripts'), 'at_events.coffee')

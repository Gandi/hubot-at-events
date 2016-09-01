# Description:
#   generic event emitter scheduled for a given time
#
# Commands:
#   hubot at version
#   hubot at <date> [in <tz>] [run <name>] do <event> [with param1=value1]
#   hubot at <date> [in <tz>] [run <name>] say [in <room>] <message>
#   hubot in <number> <unit> [run <name>] do <event> [with param1=value1]
#   hubot in <number> <unit> [run <name>] say <room> <message>
#
# Author:
#   mose

AtEvents = require '../lib/atevents'
path       = require 'path'

module.exports = (robot) ->

  at = new AtEvents robot
  robot.at = at

  withPermission = (res, cb) ->
    user = robot.brain.userForName res.envelope.user.name
    if robot.auth? and not robot.auth?.isAdmin(user)
      res.reply "You don't have permission to do that."
      res.finish()
    else
      cb()

  #   hubot at version
  robot.respond /at version$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-at-events module is version #{pkg.version}"
    res.finish()

  #   hubot at <date> [in <tz>] say [in <room>] <some message>
  robot.respond new RegExp(
    'at ([-0-9TZW:\.\+ ]+)' +
    '(?: in ([^ ]+))?' +
    ' say(?: in (#[^ ]+))? (.+) *$'
    ), (res) ->
      withPermission res, ->
        # console.log res.match
        [_, date, tz, room, message] = res.match
        unless room?
          room = res.envelope.room ? res.nvelope.reply_to
        options = "room=#{room} message=#{message}"
        at.addAt null, date, 'at.message', tz, options, (so) ->
          res.send so.message
        res.finish()

  #   hubot at <date> [in <tz>] [run <name>] do <event> [with param1=value1]
  robot.respond new RegExp(
    'at ([-0-9TZW:\.\+ ]+)' +
    '(?: in ([^ ]+))?' +
    '(?: run ([-_a-zA-Z0-9\.]+))?' +
    '(?: do ([-_a-zA-Z0-9\.]+))?' +
    '(?: with ([-_a-zA-Z0-9]+=.+)+)? *$'
    ), (res) ->
      withPermission res, ->
        # console.log res.match
        [_, date, tz, name, eventName, options] = res.match
        at.addAt name, date, eventName, tz, options, (so) ->
          res.send so.message
        res.finish()

  # sample for testing purposes
  robot.on 'at.message', (e) ->
    if e.room and e.message
      robot.messageRoom e.room, e.message

# Description:
#   generic event emitter scheduled for a given time
#
# Commands:
#   hubot at version
#
# Author:
#   mose

AtEvents = require '../lib/atevents'
path       = require 'path'

module.exports = (robot) ->

  at = new AtEvents robot
  robot.cron = cron

  withPermission = (res, cb) ->
    user = robot.brain.userForName res.envelope.user.name
    if robot.auth? and not robot.auth?.isAdmin(user)
      res.reply "You don't have permission to do that."
      res.finish()
    else
      cb()

  #   hubot at version
  robot.respond /cron version$/, (res) ->
    pkg = require path.join __dirname, '..', 'package.json'
    res.send "hubot-cron-events module is version #{pkg.version}"
    res.finish()

  #   hubot cron <name> at <date> <event> [<tz>]
  robot.respond new RegExp(
    'at (.+) run (.*)' +
    '(?: in ([^ ]+))?' +
    '(?: is ([-_a-zA-Z0-9\.]+))?' +
    '(?: with ([-_a-zA-Z0-9]+=.+)+)? *$'
    ), (res) ->
      withPermission res, ->
        name = res.match[1]
        at = res.match[2]
        tz = res.match[3]
        eventName = res.match[4]
        args = cron._extractKeys res.match[5]
        options = res.match[5]
        cron.addJob name, period, eventName, tz, options, (so) ->
          res.send so.message
        res.finish()

  # sample for testing purposes
  robot.on 'at.message', (e) ->
    if e.room and e.message
      robot.messageRoom e.room, e.message

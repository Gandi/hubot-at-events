# Description:
#   generic event emitter scheduled for a given time
#
# Commands:
#   hubot at version
#   hubot at <date> [in <tz>] [run <name>] do <event> [with param1=value1]
#   hubot at <date> [in <tz>] [run <name>] say [in <room>] <message>
#   hubot in <howmany> <unit> [run <name>] do <event> [with param1=value1]
#   hubot in <howmany> <unit> [run <name>] say <room> <message>
#   hubot at enable <name>
#   hubot at disable <name>
#   hubot at list <name>
#   hubot at cancel <name>
#
# Author:
#   mose

AtEvents = require '../lib/atevents'
path       = require 'path'

module.exports = (robot) ->

  at = new AtEvents robot
  robot.at = at

  withPermission = (res, cb) ->
    user = robot.brain.userForName(res.envelope.user.name) or res.envelope.user
    if not robot.auth?
      cb()
    else
      if robot.auth?.isAdmin(user)
        cb()
      else
        if process.env.HUBOT_AT_NOAUTH? and process.env.HUBOT_AT_NOAUTH isnt 'false'
          cb()
        else
          if process.env.HUBOT_AT_AUTH_GROUP? and
             robot.auth.hasRole(user, process.env.HUBOT_AT_AUTH_GROUP)
            cb()
          else
            res.reply "You don't have permission to do that."
            res.finish()

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
        at.addAction null, date, 'at.message', tz, options, (so) ->
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
        at.addAction name, date, eventName, tz, options, (so) ->
          res.send so.message
        res.finish()

  #   hubot in <howmany> <unit> say [in <room>] <some message>
  robot.respond new RegExp(
    'in ([0-9]+)' +
    ' *([a-z]+)' +
    ' say(?: in (#[^ ]+))? (.+) *$'
    ), (res) ->
      withPermission res, ->
        # console.log res.match
        [_, duration, unit, room, message] = res.match
        unless room?
          room = res.envelope.room ? res.nvelope.reply_to
        options = "room=#{room} message=#{message}"
        at.addIn null, duration, unit, 'at.message', options, (so) ->
          res.send so.message
        res.finish()

  #   hubot in <howmany> <unit> [run <name>] do <event> [with param1=value1]
  robot.respond new RegExp(
    'in ([0-9]+)' +
    ' *([a-z]+)' +
    '(?: run ([-_a-zA-Z0-9\.]+))?' +
    '(?: do ([-_a-zA-Z0-9\.]+))?' +
    '(?: with ([-_a-zA-Z0-9]+=.+)+)? *$'
    ), (res) ->
      withPermission res, ->
        # console.log res.match
        [_, duration, unit, name, eventName, options] = res.match
        at.addIn name, duration, unit, eventName, options, (so) ->
          res.send so.message
        res.finish()

  #   hubot at enable <name>
  robot.respond /at enable ([^ ]+) *$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      at.enableAction name, (so) ->
        res.send so.message
      res.finish()

  #   hubot at disable <name>
  robot.respond /at disable ([^ ]+) *$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      at.disableAction name, (so) ->
        res.send so.message
      res.finish()

  #   hubot at list <name>
  robot.respond /at list *([^ ]+)? *$/, (res) ->
    withPermission res, ->
      filter = res.match[1]
      at.listActions filter, (so) ->
        if Object.keys(so).length is 0
          if filter?
            res.send "There is no action matching #{filter}."
          else
            res.send 'There is no action defined.'
        else
          for k, v of so
            status = if v.started
              ''
            else
              '(disabled)'
            tz = ''
            if v.tz?
              tz = " in #{v.tz}"
            eventdata = ''
            if Object.keys(v.eventData).length > 0
              eventdata = 'with '
              for datakey, datavalue of v.eventData
                eventdata += "#{datakey}=#{datavalue} "
            res.send "at #{v.cronTime}#{tz} run #{k} do #{v.eventName} #{eventdata}#{status}"
      res.finish()

  #   hubot at cancel <name>
  robot.respond /at (?:cancel|delete|clean) ([^ ]+)$/, (res) ->
    withPermission res, ->
      name = res.match[1]
      at.deleteAction name, (so) ->
        res.send so.message
      res.finish()

  # debug
  # robot.respond /at actions$/, (res) ->
  #   console.log at.actions

  # sample for testing purposes
  robot.on 'at.message', (e) ->
    if e.room and e.message
      robot.messageRoom e.room, e.message

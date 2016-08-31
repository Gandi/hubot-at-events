# Description:
#   cron events library
#
# Author:
#   mose

CronJob = require('cron').CronJob
moment = require 'moment'

class AtEvents

  constructor: (@robot) ->
    storageLoaded = =>
      @data = @robot.brain.data.at ||= { }
      @robot.logger.debug 'AtEvents Data Loaded: ' + JSON.stringify(@data, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here
    @moments = { }
    @loadAll()

  loadAll: ->
    for name, at of @data
      if at.started
        @moments[name] = @loadAt name, at
        @moments[name].start()

  loadAt: (name, at) ->
    params = {
      cronTime: moment(at.cronTime).toDate()
      start: true
      onTick: =>
        if at.eventName?
          @robot.emit at.eventName, at.eventData
      onComplete: =>
        delete @moments[name]
    }
    if at.tz?
      params.tz = at.tz
    return new CronJob(params)

  addAt: (name, date, eventName, tz, options, cb) ->
    if @_valid date, tz
      args = @_extractKeys(options)
      if @data[name]?
        @data[name].cronTime = date
        if eventName?
          @data[name].eventName = eventName
        if tz?
          @data[name].tz = tz
        if args isnt { }
          for k, v of args
            @data[name].eventData[k] = v
        if @moments[name]?
          @_stop name
          @_start name
        cb { message: "The action #{name} updated." }
      else
        unless name?
          name = @_random_name()
        @data[name] = {
          cronTime: date,
          eventName: eventName,
          eventData: args,
          started: true,
          tz: tz
        }
        cb { message: "The action #{name} is created." }
    else
      cb { message: "Sorry, '#{date}' is not a valid pattern." }

  enableAt: (name, cb) ->
    if @data[name]?
      if @moments[name]?
        @_stop name
      @_start name
      cb { message: "The job #{name} is now in service." }
    else
      cb { message: "startJob: There is no such job named #{name}" }

  disableAt: (name, cb) ->
    if @data[name]?
      @_stop name
      cb { message: "The job #{name} is now paused." }
    else
      cb { message: "stopJob: There is no such job named #{name}" }

  statusAt: (name, cb) ->
    if @data[name]?
      if @moments[name]?
        cb { message: "The job #{name} is currently running." }
      else
        cb { message: "The job #{name} is paused." }
    else
      cb { message: "statusJob: There is no such job named #{name}" }

  deleteAt: (name, cb) ->
    if @data[name]?
      delete @data[name]
      if @moments[name]?
        @moments[name].stop()
        delete @moments[name]
      cb { message: "The job #{name} is deleted." }
    else
      cb { message: "deleteJob: There is no such job named #{name}" }

  listAt: (filter, cb) ->
    res = { }
    for k in Object.keys(@data)
      if new RegExp(filter).test k
        res[k] = @data[k]
    cb res

  addData: (name, key, value, cb) ->
    if @data[name]?
      @data[name].eventData[key] = value
      if @moments[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now defined for job #{name}." }
    else
      cb { message: "addData: There is no such job named #{name}" }

  dropData: (name, key, cb) ->
    if @data[name]?
      if @data[name].eventData[key]?
        delete @data[name].eventData[key]
      if @moments[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now removed from job #{name}." }
    else
      cb { message: "dropData: There is no such job named #{name}" }

  _start: (name) ->
    @moments[name] = @loadJAt @data[name]
    @moments[name].start()
    @data[name].started = true

  _stop: (name) ->
    if @moments[name]?
      @moments[name].stop()
      delete @moments[name]
    @data[name].started = false

  _valid: (date, tz) ->
    m = moment(date)
    if m.isValid()
      try
        new CronJob m.toDate(), null, null, false, tz
        return true
      catch e
        @robot.logger.error e
        return false
    else
      @robot.logger.error "Invalid date #{date}"
      return false

  _extractKeys: (str) ->
    args = { }
    if str?
      keys = str.split(/\=[^=]*(?: |$)/)[0...-1]
      values = str.split(/(?:(?:^| )[-_a-zA-Z0-9]+)=/)[1..]
      for i, k of keys
        args[k] = values[i]
    args

  _random_name: ->
    new Date().getTime().toString(36)



module.exports = AtEvents

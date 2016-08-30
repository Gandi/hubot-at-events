# Description:
#   cron events library
#
# Author:
#   mose

CronJob = require('cron').CronJob

class AtEvents

  constructor: (@robot) ->
    storageLoaded = =>
      @data = @robot.brain.data.at ||= { }
      @robot.logger.debug 'CronEvents Data Loaded: ' + JSON.stringify(@data, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here
    @ats = { }
    @loadAll()

  loadAll: ->
    for name, at of @data
      if at.started
        @ats[name] = @loadAt at
        @ats[name].start()

  loadAt: (at) ->
    params = {
      cronTime: at.cronTime
      start: true
      onTick: =>
        if at.eventName?
          @robot.emit at.eventName, at.eventData
      onComplete: =>
        # delete at entry
    }
    if at.tz?
      params.tz = at.tz
    return new CronJob(params)

  addAt: (name, date, eventName, tz, options, cb) ->
    # todo
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
        if @ats[name]?
          @_stop name
          @_start name
        cb { message: "The job #{name} updated." }
      else
        @data[name] = {
          cronTime: date,
          eventName: eventName,
          eventData: args,
          started: false,
          tz: tz
        }
        cb { message: "The job #{name} is created." }
    else
      cb { message: "Sorry, '#{date}' is not a valid pattern." }

  enableAt: (name, cb) ->
    if @data[name]?
      if @ats[name]?
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
      if @ats[name]?
        cb { message: "The job #{name} is currently running." }
      else
        cb { message: "The job #{name} is paused." }
    else
      cb { message: "statusJob: There is no such job named #{name}" }

  deleteAt: (name, cb) ->
    if @data[name]?
      delete @data[name]
      if @ats[name]?
        @ats[name].stop()
        delete @ats[name]
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
      if @ats[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now defined for job #{name}." }
    else
      cb { message: "addData: There is no such job named #{name}" }

  dropData: (name, key, cb) ->
    if @data[name]?
      if @data[name].eventData[key]?
        delete @data[name].eventData[key]
      if @ats[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now removed from job #{name}." }
    else
      cb { message: "dropData: There is no such job named #{name}" }

  _start: (name) ->
    @ats[name] = @loadJAt @data[name]
    @ats[name].start()
    @data[name].started = true

  _stop: (name) ->
    if @ats[name]?
      @ats[name].stop()
      delete @ats[name]
    @data[name].started = false

  _valid: (period, tz) ->
    try
      new CronJob period, null, null, false, tz
      return true
    catch e
      @robot.logger.error e
      return false

  _extractKeys: (str) ->
    args = { }
    if str?
      keys = str.split(/\=[^=]*(?: |$)/)[0...-1]
      values = str.split(/(?:(?:^| )[-_a-zA-Z0-9]+)=/)[1..]
      for i, k of keys
        args[k] = values[i]
    args



module.exports = AtEvents

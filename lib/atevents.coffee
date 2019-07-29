# Description:
#   at events library
#
# Author:
#   mose

CronJob = require('cron').CronJob
moment = require 'moment'

class AtEvents

  units: {
    's': 'seconds'
    'sec': 'seconds'
    'second': 'seconds'
    'seconds': 'seconds'
    'm': 'minutes'
    'min': 'minutes'
    'minute': 'minutes'
    'minutes': 'minutes'
    'h': 'hours'
    'hour': 'hours'
    'hours': 'hours'
    'd': 'days'
    'day': 'days'
    'days': 'days'
    'w': 'weeks'
    'week': 'weeks'
    'weeks': 'weeks'
    'month': 'months'
    'months': 'months'
    'y': 'years'
    'year': 'years'
    'years': 'years'
  }

  constructor: (@robot) ->
    storageLoaded = =>
      @data = @robot.brain.data.at ||= { }
      @robot.logger.debug 'AtEvents Data Loaded: ' + JSON.stringify(@data, null, 2)
    @robot.brain.on 'loaded', storageLoaded
    storageLoaded() # just in case storage was loaded before we got here
    @actions = { }
    @loadAll()

  loadAll: ->
    for name, at of @data
      if at.started
        if moment(at.cronTime).before(moment())
          @robot.logger.warn "ignoring #{name}, date is in the past"
        else
          @actions[name] = @loadAction name, at

  loadAction: (name, at) ->
    params = {
      cronTime: moment(at.cronTime).toDate()
      start: true
      onTick: =>
        if at.eventName?
          @robot.emit at.eventName, at.eventData
          delete @actions[name]
          delete @data[name]
    }
    if at.tz?
      params.tz = at.tz
    return new CronJob(params)

  addIn: (name, duration, unit, eventName, options, cb) ->
    if @units[unit]?
      date = moment().add(duration, @units[unit]).format('YYYY-MM-DD HH:mm')
      @addAction name, date, eventName, null, options, cb
    else
      cb { message: "Sorry, I don't know what '#{unit}' means." }

  addAction: (name, date, eventName, tz, options, cb) ->
    if @_valid date
      args = @_extractKeys(options)
      if name? and @data[name]?
        @data[name].cronTime = date
        if eventName?
          @data[name].eventName = eventName
        if tz?
          @data[name].tz = tz
        if args isnt { }
          for k, v of args
            @data[name].eventData[k] = v
        if @data[name].started
          if @actions[name]?
            @_stop name
          @_start name
        cb { message: "The action #{name} is updated." }
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
        @actions[name] = @loadAction name, @data[name]
        cb { message: "The action #{name} is created." }
    else
      cb { message: "Sorry, '#{date}' is not a valid pattern." }

  enableAction: (name, cb) ->
    @withAction name, cb, =>
      if @actions[name]?
        cb { message: "The action #{name} is already scheduled." }
      else
        @_start name
        cb { message: "The action #{name} is now scheduled." }

  disableAction: (name, cb) ->
    @withAction name, cb, =>
      if @actions[name]?
        @_stop name
        cb { message: "The action #{name} is now unscheduled." }
      else
        cb { message: "The action #{name} is actually not scheduled." }

  listActions: (filter, cb) ->
    res = { }
    for k in Object.keys(@data)
      if new RegExp(filter).test k
        res[k] = @data[k]
    cb res

  deleteAction: (name, cb) ->
    @withAction name, cb, =>
      if @actions[name]?
        @actions[name].stop()
        delete @actions[name]
      delete @data[name]
      cb { message: "The action #{name} is cancelled." }

  addData: (name, key, value, cb) ->
    @withAction name, cb, =>
      @data[name].eventData[key] = value
      if @actions[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now defined for job #{name}." }

  dropData: (name, key, cb) ->
    @withAction name, cb, =>
      if @data[name].eventData[key]?
        delete @data[name].eventData[key]
      if @actions[name]?
        @_stop name
        @_start name
      cb { message: "The key #{key} is now removed from job #{name}." }

  withAction: (name, cb, docb) ->
    if @data[name]?
      docb()
    else
      cb { message: "There is no such action named #{name}." }


  _start: (name) ->
    @actions[name] = @loadAction name, @data[name]
    @data[name].started = true

  _stop: (name) ->
    if @actions[name]?
      @actions[name].stop()
    @data[name].started = false

  _valid: (date) ->
    m = moment(date)
    if m.isValid()
      return true
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

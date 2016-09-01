require('source-map-support').install {
  handleUncaughtExceptions: false,
  environment: 'node'
}

require('es6-promise').polyfill()

Helper = require('hubot-test-helper')

# helper loads a specific script if it's a file
helper = new Helper('../scripts/at_events.coffee')

path   = require 'path'
sinon  = require 'sinon'
expect = require('chai').use(require('sinon-chai')).expect

room = null

# ---------------------------------------------------------------------------------
describe 'at_events module', ->

  hubot = (message, userName = 'momo', tempo = 40) ->
    beforeEach (done) ->
      room.user.say userName, "@hubot #{message}"
      setTimeout (done), tempo

  hubotResponse = (i = 1) ->
    room.messages[i]?[1]

  hubotResponseCount = ->
    room.messages?.length - 1

  beforeEach ->
    room = helper.createRoom { httpd: false }
    room.robot.logger.error = sinon.stub()

  # ---------------------------------------------------------------------------------
  context 'at robot launch', ->
    beforeEach ->
      room.robot.brain.data.at = {
        somejob: {
          cronTime: '2042-08-25 08:00',
          eventName: 'event1',
          eventData: { },
          started: false
        },
        other: {
          cronTime: '2042-08-25 08:00',
          eventName: 'event2',
          eventData: { },
          started: true,
          tz: 'UTC'
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.at.loadAll()

    afterEach ->
      room.robot.brain.data.at = { }
      room.robot.at.actions = { }

    context 'when brain is loaded', ->
      it 'jobs stored as not started are not started', ->
        expect(room.robot.at.actions.somejob).not.to.be.defined
      it 'jobs stored as started are started', ->
        expect(room.robot.at.actions.other).to.be.defined
      it 'job in brain should have a tz recorded', ->
        expect(room.robot.brain.data.at.other.tz).to.eql 'UTC'


  # ---------------------------------------------------------------------------------
  context 'user wants to know hubot-at-events version', ->

    context 'at version', ->
      hubot 'at version'
      it 'should reply version number', ->
        expect(hubotResponse()).
          to.match /hubot-at-events module is version [0-9]+\.[0-9]+\.[0-9]+/
        expect(hubotResponseCount()).to.eql 1

  # ---------------------------------------------------------------------------------
  context 'user adds a new message action', ->
    context 'with a valid date', ->
      hubot 'at 2042-09-25 08:00 say something to say'
      it 'should not complain about the date syntax', ->
        expect(hubotResponse()).to.match /The action [a-z0-9]+ is created\./
      it 'records the new action in the brain', ->
        expect(Object.keys(room.robot.brain.data.at).length).to.eql 1
      it 'records crontime properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].cronTime).to.eql '2042-09-25 08:00'
      it 'records eventname properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventName).to.eql 'at.message'
      it 'records room properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventData.room).to.eql 'room1'
      it 'records message properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventData.message).to.eql 'something to say'

    context 'when room is specified', ->
      hubot 'at 2042-09-25 08:00 say in #dev something to say'
      it 'should not complain about the date syntax', ->
        expect(hubotResponse()).to.match /The action [a-z0-9]+ is created\./
      it 'records the new action in the brain', ->
        expect(Object.keys(room.robot.brain.data.at).length).to.eql 1
      it 'records crontime properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].cronTime).to.eql '2042-09-25 08:00'
      it 'records eventname properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventName).to.eql 'at.message'
      it 'records room properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventData.room).to.eql '#dev'
      it 'records message properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventData.message).to.eql 'something to say'


  # ---------------------------------------------------------------------------------
  context 'user adds a new action', ->

    context 'with an invalid date', ->
      hubot 'at 2042-09-25 08:80 do some.event'
      it 'should complain about the period syntax', ->
        expect(hubotResponse()).to.eql "Sorry, '2042-09-25 08:80' is not a valid pattern."
      it 'should log an error', ->
        expect(room.robot.logger.error).calledOnce
      it 'should log an error talking about date format', ->
        expect(room.robot.logger.error).calledWith 'Invalid date 2042-09-25 08:80'

    context 'with a valid date', ->
      hubot 'at 2042-09-25 08:00 do some.event'
      it 'should not complain about the date syntax', ->
        expect(hubotResponse()).to.match /The action [a-z0-9]+ is created\./
      it 'records the new action in the brain', ->
        expect(Object.keys(room.robot.brain.data.at).length).to.eql 1
      it 'records crontime properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].cronTime).to.eql '2042-09-25 08:00'
      it 'records eventname properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].eventName).to.eql 'some.event'

    context 'with a valid date and a name', ->
      hubot 'at 2042-09-25 08:00 run somejob do some.event'
      it 'should not complain about the date syntax', ->
        expect(hubotResponse()).to.eql 'The action somejob is created.'
      it 'records the new action in the brain', ->
        expect(room.robot.brain.data.at.somejob).to.exist
      it 'records crontime properly', ->
        expect(room.robot.brain.data.at.somejob.cronTime).to.eql '2042-09-25 08:00'
      it 'records eventname properly', ->
        expect(room.robot.brain.data.at.somejob.eventName).to.eql 'some.event'

    context 'with a valid date and a tz', ->
      hubot 'at 2042-09-25 08:00 in UTC do some.event'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.match /The action [a-z0-9]+ is created\./
      it 'records timezone properly', ->
        name = Object.keys(room.robot.brain.data.at)[0]
        expect(room.robot.brain.data.at[name].tz).to.eql 'UTC'

    context 'with a valid date and a name and a tz', ->
      hubot 'at 2042-09-25 08:00 in UTC run somejob do some.event'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The action somejob is created.'
      it 'records timezone properly', ->
        expect(room.robot.brain.data.at.somejob.tz).to.eql 'UTC'

    context 'with a valid date and some data', ->
      hubot 'at 2042-09-25 run somejob do some.event with param1=something'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The action somejob is created.'
      it 'records first param properly', ->
        expect(room.robot.brain.data.at.somejob.eventData.param1).to.eql 'something'

    context 'with a valid date and some multiple data', ->
      hubot 'at 2042-09-25 run somejob do some.event with param1=something param2=another'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The action somejob is created.'
      it 'records first param properly', ->
        expect(room.robot.brain.data.at.somejob.eventData.param1).to.eql 'something'
      it 'records second param properly', ->
        expect(room.robot.brain.data.at.somejob.eventData.param2).to.eql 'another'

    context 'with a valid date and some data with spaces', ->
      hubot 'at 2042-09-25 run somejob do some.event ' +
            'with param1=something and whatever param2=another'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The action somejob is created.'
      it 'records first param properly', ->
        expect(room.robot.brain.data.at.somejob.eventData.param1).to.eql 'something and whatever'
      it 'records second param properly', ->
        expect(room.robot.brain.data.at.somejob.eventData.param2).to.eql 'another'

    context 'and action already runs', ->
      beforeEach ->
        room.robot.brain.data.at = {
          somejob: {
            cronTime: '2042-08-25 08:00',
            eventName: 'event2',
            eventData: {
              someparam: 'somevalue'
            },
            started: true
          }
        }
        room.robot.brain.emit 'loaded'
        room.robot.at.loadAll()

      afterEach ->
        room.robot.brain.data.at = { }
        room.robot.at.actions = { }

      context 'with simple date update', ->
        hubot 'at 2042-08-25 20:00 run somejob'
        it 'should change the action', ->
          expect(hubotResponse()).to.eql 'The action somejob is updated.'
        it 'should have still have the job in the actions queue', ->
          expect(room.robot.at.actions.somejob).to.be.defined
        it 'change the crontime', ->
          expect(room.robot.brain.data.at.somejob.cronTime).to.eql '2042-08-25 20:00'
        it 'change the event name', ->
          expect(room.robot.brain.data.at.somejob.eventName).to.eql 'event2'

      context 'with tz update', ->
        hubot 'at 2042-08-25 20:00 in CEST run somejob'
        it 'should change the action', ->
          expect(hubotResponse()).to.eql 'The action somejob is updated.'
        it 'records timezone properly', ->
          expect(room.robot.brain.data.at.somejob.tz).to.eql 'CEST'

      context 'with eventname update', ->
        hubot 'at 2042-08-25 20:00 run somejob do event3'
        it 'should change the action', ->
          expect(hubotResponse()).to.eql 'The action somejob is updated.'
        it 'change the event name', ->
          expect(room.robot.brain.data.at.somejob.eventName).to.eql 'event3'

      context 'with data addition', ->
        hubot 'at 2042-08-25 08:00 run somejob with param1=value1'
        it 'should change the action', ->
          expect(hubotResponse()).to.eql 'The action somejob is updated.'
        it 'keeps existing param', ->
          expect(room.robot.brain.data.at.somejob.eventData.someparam).to.eql 'somevalue'
        it 'adds the new param', ->
          expect(room.robot.brain.data.at.somejob.eventData.param1).to.eql 'value1'

      context 'with data update', ->
        hubot 'at 2042-08-25 08:00 run somejob with someparam=value1'
        it 'should change the action', ->
          expect(hubotResponse()).to.eql 'The action somejob is updated.'
        it 'updates existing param', ->
          expect(room.robot.brain.data.at.somejob.eventData.someparam).to.eql 'value1'


  # ---------------------------------------------------------------------------------
  context 'user starts an action', ->
    beforeEach ->
      room.robot.brain.data.at = {
        somejob: {
          cronTime: '2042-08-25 08:00',
          eventName: 'event1',
          eventData: { },
          started: false
        },
        another: {
          cronTime: '2042-08-25 08:00',
          eventName: 'event2',
          eventData: { },
          started: true
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.at.loadAll()

    afterEach ->
      room.robot.brain.data.at = { }
      room.robot.at.actions = { }

    context 'but action is not known', ->
      hubot 'at enable nojob'
      it 'should complain about the nonexistence of that action', ->
        expect(hubotResponse()).to.eql 'There is no such action named nojob'
      it 'should not have added an action in the actions queue', ->
        expect(room.robot.at.actions.nojob).not.to.be.defined

    context 'and action exists', ->
      hubot 'at enable somejob'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The action somejob is now scheduled.'
      it 'should change brain to record it\'s scheduled', ->
        expect(room.robot.brain.data.at.somejob.started).to.be.true
      it 'should have added an action in the actions queue', ->
        expect(room.robot.at.actions.somejob).to.be.defined

    context 'and action exists and runs', ->
      hubot 'at enable another'
      it 'should not complain about the period syntax', ->
        expect(hubotResponse()).to.eql 'The action another is already scheduled.'
      it 'should change brain to record it\'s still started', ->
        expect(room.robot.brain.data.at.another.started).to.be.true
      it 'should have added a job in the jobs queue', ->
        expect(room.robot.at.actions.another).to.be.defined

  # ---------------------------------------------------------------------------------
  context 'user stops a job', ->
    beforeEach ->
      room.robot.brain.data.at = {
        somejob: {
          cronTime: '2042-08-25 08:00',
          eventName: 'event1',
          eventData: { },
          started: true
        },
        another: {
          cronTime: '2042-08-25 08:00',
          eventName: 'event2',
          eventData: { },
          started: false
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.at.loadAll()

    afterEach ->
      room.robot.brain.data.at = { }
      room.robot.at.actions = { }

    context 'but action is not known', ->
      hubot 'at disable nojob'
      it 'should complain about the nonexistence of that job', ->
        expect(hubotResponse()).to.eql 'There is no such action named nojob'
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.at.actions.somejob).not.to.be.defined

    context 'and job exists', ->
      hubot 'at disable somejob'
      it 'should not complain about the nonexistence of that job', ->
        expect(hubotResponse()).to.eql 'The action somejob is now unscheduled.'
      it 'should change brain to record it\'s not started', ->
        expect(room.robot.brain.data.at.somejob.started).to.be.false
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.at.actions.somejob).to.be.undefined

    context 'and job exists and is not scheduled', ->
      hubot 'at disable another'
      it 'should not complain about the nonexistence of that job', ->
        expect(hubotResponse()).to.eql 'The action another is actually not scheduled.'
      it 'should change brain to record it\'s not started', ->
        expect(room.robot.brain.data.at.another.started).to.be.false
      it 'should not have added a job in the jobs queue', ->
        expect(room.robot.at.actions.another).to.be.undefined


  # ---------------------------------------------------------------------------------
  context 'events listeners', ->
    it 'should know about at.message', ->
      expect(room.robot.events['at.message']).to.be.defined

    context 'for at.message', ->
      beforeEach (done) ->
        room.robot.emit 'at.message', { room: 'room1', message: 'ha' }
        setTimeout (done), 50

      it 'should say that param is added to data', ->
        expect(hubotResponse(0)).to.eql 'ha'

  # ---------------------------------------------------------------------------------
  context 'events triggers', ->
    beforeEach ->
      room.robot.brain.data.at = {
        somejob: {
          cronTime: '2042-08-25 20:00',
          eventName: 'at.message',
          eventData: { room: 'room1', message: 'ha' },
          started: true,
          tz: undefined
        }
      }
      room.robot.brain.emit 'loaded'
      room.robot.at.loadAll()

    afterEach ->
      room.robot.brain.data.at = { }
      room.robot.at.actions = { }

    context 'it fires a action on tick', ->
      beforeEach ->
        room.robot.at.actions.somejob.fireOnTick()
      it 'should say something', ->
        expect(hubotResponse(0)).to.eql 'ha'

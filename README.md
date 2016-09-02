Hubot At Events Plugin
=================================

[![Version](https://img.shields.io/npm/v/hubot-at-events.svg)](https://www.npmjs.com/package/hubot-at-events)
[![Downloads](https://img.shields.io/npm/dt/hubot-at-events.svg)](https://www.npmjs.com/package/hubot-at-events)
[![Build Status](https://img.shields.io/travis/Gandi/hubot-at-events.svg)](https://travis-ci.org/Gandi/hubot-at-events)
[![Dependency Status](https://gemnasium.com/Gandi/hubot-at-events.svg)](https://gemnasium.com/Gandi/hubot-at-events)
[![Coverage Status](https://img.shields.io/codeclimate/coverage/github/Gandi/hubot-at-events.svg)](https://codeclimate.com/github/Gandi/hubot-at-events/coverage)
[![Code Climate](https://img.shields.io/codeclimate/github/Gandi/hubot-at-events.svg)](https://codeclimate.com/github/Gandi/hubot-at-events)

This plugin is the brother of [hubot-cron-events](https://github.com/Gandi/hubot-cron-events) but specialised in one-time events triggered at a given time.

*Work in progress* - this plugin is ready for use but still very experimental.


Installation
--------------
In your hubot directory:    

    npm install hubot-at-events --save

Then add `hubot-at-events` to `external-scripts.json`


Configuration
-----------------

If you use [hubot-auth](https://github.com/hubot-scripts/hubot-auth), the plugin configuration commands will be restricted to user with the `admin` role. 

But if hubot-auth is not loaded, all users can access those commands.

It's also advised to use a brain persistence plugin, whatever it is, to persist the cron jobs between restarts.


Commands
--------------

**Note: until version 1.0.0, this readme is a roadmap, not a real documentation. This is a Readme-driven development approach.**

Commands prefixed by `.at` or `.in` are here taking in account we use the `.` as hubot prefix, just replace it with your prefix if it is different. Uncommented commands are just not yet implemented.

    .at version
        gives the version of the hubot-at-events package loaded

    .at <date> [in <tz>] [run <name>] do <event> [with param1=value1]
        schedules triggering of <event> at given <date>
        - <date> has to be in the future
        - params can be provided to be transmitted to the <event>
        - if you don't provide a <name> for the action (using 'run <name>')
          then a random name will be attributed to it,
          as it's needed for later cancellation or modification
        - if no <tz> is provided, the server tz will be applied

    .at <date> [in <tz>] [run <name>] say [in <room>] <message>
        same as above, except that the aevent will be 'at.message'
        - if the <room> is omitted, it will be set to the room 
          where the command is done
        - the action will be given a random name.

    .in <number> <unit> [run <name>] do <event> [with param1=value1]
        same as with .at command, but using time relative to now
        acceptable units are
        - s, sec, second, seconds
        - m, min, minute, minutes
        - h, hour, hours
        - d, day, days
        - w, week, weeks
        - month, months
        - y, year, years
        For the rest, it behaves exactly like the .at command

    .in <number> <unit> [run <name>] say <room> <message>
        same as the equivalent '.at <date> say' command

    .at enable <name>
        activate an action that was previously disabled

    .at disable <name>
        disable an action but without deleting it, so it can be re-enabled later

    .at list [<term>]
        will list all actions matching <term>
        if no <term> is provided, it will just list all actions

    .at cancel <name>
        removes the action, all data about it will be lost

    .at <name> with <key> = <value>

    .at <name> drop <key>

Some events receivers are also provided for testing purposes:

    at.message
        requires data:
        - room
        - message
        it will just say the message in the given room


Testing
----------------

    npm install

    # will run make test and coffeelint
    npm test 
    
    # or
    make test
    
    # or, for watch-mode
    make test-w

    # or for more documentation-style output
    make test-spec

    # and to generate coverage
    make test-cov

    # and to run the lint
    make lint

    # run the lint and the coverage
    make

Changelog
---------------
All changes are listed in the [CHANGELOG](CHANGELOG.md)

Contribute
--------------
Feel free to open a PR if you find any bug, typo, want to improve documentation, or think about a new feature. 

Gandi loves Free and Open Source Software. This project is used internally at Gandi but external contributions are **very welcome**. 

Authors
------------
- [@mose](https://github.com/mose) - author and maintainer

License
-------------
This source code is available under [MIT license](LICENSE).

Copyright
-------------
Copyright (c) 2016 - Gandi - https://gandi.net

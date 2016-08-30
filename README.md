Hubot At Events Plugin
=================================

[![Build Status](https://img.shields.io/travis/Gandi/hubot-at-events.svg)](https://travis-ci.org/Gandi/hubot-at-events)
[![Dependency Status](https://gemnasium.com/Gandi/hubot-at-events.svg)](https://gemnasium.com/Gandi/hubot-at-events)
[![Coverage Status](https://img.shields.io/codeclimate/coverage/github/Gandi/hubot-at-events.svg)](https://codeclimate.com/github/Gandi/hubot-at-events/coverage)
[![Code Climate](https://img.shields.io/codeclimate/github/Gandi/hubot-at-events.svg)](https://codeclimate.com/github/Gandi/hubot-at-events)

This plugin is the brother of [hubot-cron-events](https://github.com/Gandi/hubot-cron-events) but specialised in one-time events triggered at a given time.


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

**Note: until version 1.0.0, thos readme is a roadmap, not a real documentation. This is a Readme-driven development approach.**

Commands prefixed by `.at` or `.in` are here taking in account we use the `.` as hubot prefix, just replace it with your prefix if it is different.

    .at version
        gives the version of the hubot-at-events package loaded

    .at <date> run <name> do <event> [with param1=value1]
    .at <date> run <name> say <room> <message>
    .in <number> <seconds|minutes|hours|days|weeks|months> run <name> do <event> [with param1=value1]
    .in <number> <seconds|minutes|hours|days|weeks|months> run <name> say <room> <message>


    .at when <name>

    .at list [<term>]

    .at disable <name>

    .at enable <name>

    .at cancel <name>

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

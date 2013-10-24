###
The MIT License (MIT)

Copyright (c) 2013 Tim Düsterhus

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

mailparser = new (require 'mailparser').MailParser
fs = require 'fs'
validator = require './validator'

try
	filename = "#{__dirname}/config"
	
	# configuration file was passed via `process.argv`
	filename = (require 'path').resolve process.argv[2] if process.argv[2]?
	
	filename = fs.realpathSync filename
	
	config = require filename
catch e
	console.error """[#{do Date}] Cannot load config: #{e}"""
	process.exit 1

config.logFile ?= "#{__dirname}/actions.log"
config.validIfNotFound ?= no
config.ccValid ?= yes
config.multipleFromHandling ?= "drop" # validateAll and validateOne are possible as well
config.multipleToHandling ?= "validateOne" # validateAll is possible as wel

log = (message) ->
	return unless config.logFile
	fs.appendFileSync config.logFile, """[#{do Date}] #{message}\n"""

# validate config
unless config.mymail?
	log "Missing value for mymail"
	process.exit 1

unless config.multipleFromHandling in [ "drop", "validateAll", "validateOne" ]
	log """Invalid value for multipleFromHandling (expected one of [ "drop", "validateAll", "validateOne" ], found #{config.multipleFromHandling}"""
	process.exit 1

unless config.multipleToHandling in [ "validateAll", "validateOne" ]
	log """Invalid value for multipleToHandling (expected one of [ "validateAll", "validateOne" ], found #{config.multipleToHandling}"""
	process.exit 1

# wait until we received the complete mail
mailparser.on 'end', (mail) ->
	if mail.from.length is 1 or config.multipleFromHandling in [ "validateAll", "validateOne" ]
		fromDomains = (from.address.substring (from.address.lastIndexOf '@') + 1 for from in mail.from)
		recipients = (recipient.address for recipient in mail.to.concat (if config.ccValid and mail.cc? then mail.cc else [ ]))
		
		try
			result = validator fromDomains, recipients, config
		catch e
			log e
			process.exit 1
		if result
			log "[Accepted] qmail-aliasfilter accepted an email from [ #{(from.address for from in mail.from)} ] to [ #{(recipient for recipient in recipients)} ]"
			process.exit 0
		else
			log "[Rejected] qmail-aliasfilter rejected an email from [ #{(from.address for from in mail.from)} ] to [ #{(recipient for recipient in recipients)} ]"
			process.exit 99
	else
		log "[Rejected] qmail-aliasfilter rejected an email from [ #{(from.address for from in mail.from)} ] to [ #{(recipient for recipient in recipients)} ]"
		process.exit 99
		
process.stdin.pipe mailparser

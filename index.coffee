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

try
	config = require './config'
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

escapeRegExp = (string) -> String(string).replace /([.*+?^=!:${}()|[\]\/\\])/g, '\\$1'

# wait until we received the complete mail
mailparser.on 'end', (mail) ->
	if mail.from.length is 1 or config.multipleFromHandling in [ "validateAll", "validateOne" ]
		fromDomains = (from.address.substring (from.address.lastIndexOf '@') + 1 for from in mail.from)
		recipients = mail.to.concat (if config.ccValid and mail.cc? then mail.cc else [ ])
		
		result = do ->
			foundMyMail = no
			for recipient in recipients
				if matches = recipient.address.match config.mymail
					unless matches[1]?
						log """Missing capturing group in mymail (found #{config.mymail})"""
						process.exit 1
						
					foundMyMail = yes
					
					allowed = matches[1].split /\+/
					allowed = (for allowedDomain in allowed
						# *.example.*
						if /^\.(.*\.)?$/.test allowedDomain
							escapeRegExp allowedDomain
						# *.example.com
						else if /^\..*[^.]$/.test allowedDomain
							(escapeRegExp allowedDomain) + '$'
						# example.*
						else if /^[^.].*\.$/.test allowedDomain
							'^' + escapeRegExp allowedDomain
						# example.com
						else
							'^' + (escapeRegExp allowedDomain) + '$'
					)
					allowedRegex = new RegExp '(' + (allowed.join '|') + ')', 'i'
					
					toResult = do ->
						switch config.multipleFromHandling
							# all domains have to match
							when "validateAll"
								for from in fromDomains
									unless allowedRegex.test from
										return false
								true
							# at least one domain has to match
							when "validateOne"
								for from in fromDomains
									return true if allowedRegex.test from
								false
							# the domain has to match
							when "drop"
								if allowedRegex.test fromDomains[0]
									true
								else
									false
					switch config.multipleToHandling
						when "validateOne"
							# at least one recipient matched -> return true
							return true if toResult
						when "validateAll"
							# at least one recipient did not match -> return false
							return false unless toResult
			if foundMyMail
				switch config.multipleToHandling
					when "validateOne"
						# we would have early aborted by now if any mail was valid
						return false
					when "validateAll"
						# we would have early aborted by now if any mail was invalid
						return true
			config.validIfNotFound
			
		if result
			log "[Accepted] qmail-aliasfilter accepted an email from [ #{(from.address for from in mail.from)} ] to [ #{(recipient.address for recipient in recipients)} ]"
			process.exit 0
		else
			log "[Rejected] qmail-aliasfilter rejected an email from [ #{(from.address for from in mail.from)} ] to [ #{(recipient.address for recipient in recipients)} ]"
			process.exit 99
	else
		log "[Rejected] qmail-aliasfilter rejected an email from [ #{(from.address for from in mail.from)} ] to [ #{(recipient.address for recipient in recipients)} ]"
		process.exit 99
		
process.stdin.pipe mailparser

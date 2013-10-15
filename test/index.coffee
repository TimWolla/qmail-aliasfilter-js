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

should = require 'should'
validator = require '../validator'

getRandomString = -> Math.random().toString(36).substring 2
	
describe 'validator', ->
	it 'should return true on exact match', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'company.test' ], [ 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com' ], config).should.be.true
		
		random = "#{do getRandomString}.test"
		(validator [ random ], [ "mymail-#{random}@example.com" ], config).should.be.true
		
		config.validIfNotFound = true
		
		(validator [ 'company.test' ], [ 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com' ], config).should.be.true
		
		random = "#{do getRandomString}.test"
		(validator [ random ], [ "mymail-#{random}@example.com" ], config).should.be.true
	it 'should return false on invalid exact match', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mail.mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mail.company.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'example.net' ], [ 'mymail-example.com@example.com' ], config).should.be.false
		
		random = "#{do getRandomString}.test"
		random2 = "#{do getRandomString}.example"
		(validator [ random ], [ "mymail-#{random2}@example.com" ], config).should.be.false
		
		config.validIfNotFound = true
		
		(validator [ 'mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mail.mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mail.company.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'example.net' ], [ 'mymail-example.com@example.com' ], config).should.be.false
		
		random = "#{do getRandomString}.test"
		random2 = "#{do getRandomString}.example"
		(validator [ random ], [ "mymail-#{random2}@example.com" ], config).should.be.false
	it 'should return true for any subdomain of a valid domain when valid domain starts with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'mail.company.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.true
		(validator [ 'mx5.mail.company.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.true
		(validator [ 'mailer.example.com' ], [ 'mymail-.example.com@example.com' ], config).should.be.true
		
		random = "#{do getRandomString}.test"
		(validator [ "#{do getRandomString}.#{random}" ], [ "mymail-.#{random}@example.com" ], config).should.be.true
		
		config.validIfNotFound = true
		
		(validator [ 'mail.company.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.true
		(validator [ 'mx5.mail.company.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.true
		(validator [ 'mailer.example.com' ], [ 'mymail-.example.com@example.com' ], config).should.be.true
		
		random = "#{do getRandomString}.test"
		(validator [ "#{do getRandomString}.#{random}" ], [ "mymail-.#{random}@example.com" ], config).should.be.true
	it 'should return false for any subdomain of an invalid domain when valid domain starts with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'mail.mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mx5.mail.mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mailer.example.net' ], [ 'mymail-example.com@example.com' ], config).should.be.false
		(validator [ 'mail.mycompany.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.false
		(validator [ 'mailer.example.net' ], [ 'mymail-.example.com@example.com' ], config).should.be.false
		
		config.validIfNotFound = true
		
		(validator [ 'mail.mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mx5.mail.mycompany.test' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'mailer.example.net' ], [ 'mymail-example.com@example.com' ], config).should.be.false
		(validator [ 'mail.mycompany.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.false
		(validator [ 'mailer.example.net' ], [ 'mymail-.example.com@example.com' ], config).should.be.false
	it 'should return false w/o subdomain when valid domain starts with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'company.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-.example.com@example.com' ], config).should.be.false
		
		config.validIfNotFound = true
		
		(validator [ 'company.test' ], [ 'mymail-.company.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-.example.com@example.com' ], config).should.be.false
	it 'should return true for any tld of a valid domain when valid domain ends with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'company.test' ], [ 'mymail-company.@example.com' ], config).should.be.true
		(validator [ 'mail.company.test' ], [ 'mymail-mail.company.@example.com' ], config).should.be.true
		
		config.validIfNotFound = true
		
		(validator [ 'company.test' ], [ 'mymail-company.@example.com' ], config).should.be.true
		(validator [ 'mail.company.test' ], [ 'mymail-mail.company.@example.com' ], config).should.be.true
	it 'should return false for any tld of an invalid domain when valid domain ends with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'mycompany.test' ], [ 'mymail-company.@example.com' ], config).should.be.false
		(validator [ 'mail.mycompany.test' ], [ 'mymail-mail.company.@example.com' ], config).should.be.false
		
		config.validIfNotFound = true
		
		(validator [ 'mycompany.test' ], [ 'mymail-company.@example.com' ], config).should.be.false
		(validator [ 'mail.mycompany.test' ], [ 'mymail-mail.company.@example.com' ], config).should.be.false
	it 'should return true for any subdomain and tld of a valid domain when valid domain starts and ends with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'mail.company.test' ], [ 'mymail-.company.@example.com' ], config).should.be.true
		(validator [ 'mx5.mail.company.test' ], [ 'mymail-.company.@example.com' ], config).should.be.true
		
		config.validIfNotFound = true
		
		(validator [ 'mail.company.test' ], [ 'mymail-.company.@example.com' ], config).should.be.true
		(validator [ 'mx5.mail.company.test' ], [ 'mymail-.company.@example.com' ], config).should.be.true
	it 'should return true for any subdomain and tld of an invalid domain when valid domain starts and ends with a dot', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'mail.mycompany.test' ], [ 'mymail-.company.@example.com' ], config).should.be.false
		(validator [ 'mx5.mail.mycompany.test' ], [ 'mymail-.company.@example.com' ], config).should.be.false
		
		config.validIfNotFound = true
		
		(validator [ 'mail.mycompany.test' ], [ 'mymail-.company.@example.com' ], config).should.be.false
		(validator [ 'mx5.mail.mycompany.test' ], [ 'mymail-.company.@example.com' ], config).should.be.false
	it 'should return true if at least one recipient matches and multipleToHandling is "validateOne"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com', 'mymail-.com@example.com' ], config).should.be.true
		
		config.validIfNotFound = true
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com', 'mymail-.com@example.com' ], config).should.be.true
	it 'should return false if no recipient (of multiple) matches', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateOne"
			logFile: false
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-othercompany.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-example.org@example.com', 'mymail-example.net@example.com' ], config).should.be.false
		
		config.multipleToHandling = "validateAll"
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-othercompany.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-example.org@example.com', 'mymail-example.net@example.com' ], config).should.be.false
		
		config.validIfNotFound = true
		config.multipleToHandling = "validateOne"
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-othercompany.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-example.org@example.com', 'mymail-example.net@example.com' ], config).should.be.false
		
		config.multipleToHandling = "validateAll"
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-othercompany.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-example.org@example.com', 'mymail-example.net@example.com' ], config).should.be.false
	it 'should return true if all recipients match and multipleToHandling is "validateAll"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateAll"
			logFile: false
			
		(validator [ 'company.test' ], [ 'mymail-.test@example.com', 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com', 'mymail-.com@example.com' ], config).should.be.true
		
		config.validIfNotFound = true
		
		(validator [ 'company.test' ], [ 'mymail-.test@example.com', 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com', 'mymail-.com@example.com' ], config).should.be.true
	it 'should return false if not all recipients match and multipleToHandling is "validateAll"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateAll"
			logFile: false
			
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com', 'mymail-example.net@example.com' ], config).should.be.false
		
		config.validIfNotFound = true
		
		(validator [ 'company.test' ], [ 'mymail-mycompany.test@example.com', 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'mymail-example.com@example.com', 'mymail-example.net@example.com' ], config).should.be.false
	it 'should return false if mymail was not found and validIfNotFound is false', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "drop"
			multipleToHandling: "validateAll"
			logFile: false
			
		(validator [ 'company.test' ], [ 'othermail@example.com' ], config).should.be.false
		(validator [ 'example.com' ], [ 'othermail-example.com@example.com' ], config).should.be.false
	it 'should return true if mymail was not found and validIfNotFound is true', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: true
			multipleFromHandling: "drop"
			multipleToHandling: "validateAll"
			logFile: false
			
		(validator [ 'company.test' ], [ 'othermail@example.com' ], config).should.be.true
		(validator [ 'example.com' ], [ 'othermail-example.com@example.com' ], config).should.be.true
	it 'should throw an error if the capturing group is missing', ->
		(->
			config =
				mymail: /^mymail-.*@/
				validIfNotFound: false
				multipleFromHandling: "drop"
				multipleToHandling: "validateOne"
				logFile: false
		
			validator [ 'company.test' ], [ 'mymail-company.test@example.com' ], config
		).should.throw()
	it 'should return true if at least one of the senders match and multipleFromHandling is "validateOne"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "validateOne"
			multipleToHandling: "validateOne"
			logFile: false
			
		(validator [ 'company.test', 'example.com' ], [ 'mymail-company.test@example.com' ], config).should.be.true
		(validator [ 'company.test', 'example.com' ], [ 'mymail-example.com@example.com' ], config).should.be.true
	it 'should return false if at none of the senders match and multipleFromHandling is "validateOne" or "validateAll"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "validateOne"
			multipleToHandling: "validateOne"
			logFile: false
			
		(validator [ 'mycompany.test', 'example.com' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'company.test', 'example.net' ], [ 'mymail-example.com@example.com' ], config).should.be.false
		
		config.multipleFromHandling = "validateAll"
		
		(validator [ 'mycompany.test', 'example.com' ], [ 'mymail-company.test@example.com' ], config).should.be.false
		(validator [ 'company.test', 'example.net' ], [ 'mymail-example.com@example.com' ], config).should.be.false
	it 'should return true if all of the senders match and multipleFromHandling is "validateAll"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "validateAll"
			multipleToHandling: "validateOne"
			logFile: false
			
		(validator [ 'company.test', 'example.test' ], [ 'mymail-.test@example.com' ], config).should.be.true
	it 'should return false if at least one of the senders does match and multipleFromHandling is "validateAll"', ->
		config =
			mymail: /^mymail-(.*)@/
			validIfNotFound: false
			multipleFromHandling: "validateAll"
			multipleToHandling: "validateOne"
			logFile: false
			
		(validator [ 'company.test', 'example.com' ], [ 'mymail-company.test@example.com' ], config).should.be.false

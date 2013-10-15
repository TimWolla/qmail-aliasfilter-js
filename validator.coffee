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

escapeRegExp = (string) -> String(string).replace /([.*+?^=!:${}()|[\]\/\\])/g, '\\$1'

module.exports = (fromDomains, recipients, config) ->
	foundMyMail = no
	for recipient in recipients
		# ignore emails that don't match mymail
		if matches = recipient.match config.mymail
			# abort if the domain group was not found
			unless matches[1]?
				log """Missing capturing group in mymail (found #{config.mymail})"""
				process.exit 1
			
			foundMyMail = yes
			
			# build regex for valid domains
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
			
			result = do ->
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
					return true if result
				when "validateAll"
					# at least one recipient did not match -> return false
					return false unless result
	if foundMyMail
		switch config.multipleToHandling
			when "validateOne"
				# we would have early aborted by now if any mail was valid
				return false
			when "validateAll"
				# we would have early aborted by now if any mail was invalid
				return true
	config.validIfNotFound

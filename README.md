qmail-aliasfilter-js [![Build Status](https://travis-ci.org/TimWolla/qmail-aliasfilter-js.png?branch=master)](https://travis-ci.org/TimWolla/qmail-aliasfilter-js)
====================

qmail-aliasfilter filters incoming mail based on valid sender domains encoded into the receiving email address.

Examples
--------

- mymail-**example.com**@example.com only accepts mail with example.com as sender
- mymail-**.example.com**@example.com only accepts mail with *.example.com as sender
- mymail-**example.com+example.net**@example.com only accepts mail with example.com or example.net as sender

Configuration
-------------

```js
module.exports = {
	mymail: /^mymail-(.*)@/,           // regex to detect your own email address
	                                   // must contain a capturing group for the domainlist
	validIfNotFound: false,            // if true the mail will be accepted in your email address
	                                   // is not in the list of visible recipients
	ccValid: true,                     // if false the email will be rejected if you are only on cc
	multipleFromHandling: "drop",      // "drop" will reject the mail if there are multiple senders
	                                   // "validateAll" will validate every single sender
	                                   // "validateOne" will accept the email if at least one sender
	                                   // is valid
	multipleToHandling: "validateOne", // "validateOne" will accept the email if at least one
	                                   // recipient (To and CC) is valid
	                                   // "validateAll" will validate every single recipient
	logFile: __dirname + '/actions.log'// path to the log file
};
```

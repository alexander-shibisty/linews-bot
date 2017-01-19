log4js = require "log4js"

module.exports =
	run: (file) ->
		log4js.loadAppender "file"
		log4js.addAppender log4js.appenders.file(file), file
	info: (file, data) ->
		logger = log4js.getLogger file
		logger.info data
	warn: (file, data) ->
		logger = log4js.getLogger file
		logger.warn data
	error: (file, data) ->
		logger = log4js.getLogger file
		logger.error data
	writeTo: (file, data) ->
		console.log data
		this.run file
		this.info file, data

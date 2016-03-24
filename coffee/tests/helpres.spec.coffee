log	 = require "../helpers/logs"
date	= require "../helpers/date"
fs = require 'fs'

describe(
	"Helpers tests"
	->
		it(
			"should return date in format 'd.m'"
			->
				pattern =
				///
					([0-9]+)
					\.
					([0-9]+)
				///

				expect(date.toDay()).toMatch pattern
		)

		it(
			"should return today date"
			->
				sdate  = new Date()

				expect(date.toDay()).toEqual "#{do sdate.getDate}.#{do sdate.getMonth + 1}"
		)

		it(
			"should write to log"
			(done) ->
				file = "logs/test.log"
				log.writeTo file, "test"

				fs.readFile(
					"#{file}"
					"utf8"
					(err, data) ->
						expect(data.length > 0).toEqual true
						do done
				)
		)
)

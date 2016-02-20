log	 = require "../helpers/logs"
date	= require "../helpers/date"
fs = require 'fs'

describe(
	"Routes tests"
	->
		it("should return date in format 'd.m'", () ->
			expect(date.toDay()).toMatch(/([0-9]+)\.([0-9]+)/)
		)

		it("should return today date", () ->
			sdate  = new Date()
			expect(date.toDay()).toEqual("#{do sdate.getDate}.#{do sdate.getMonth + 1}")
		)

		it("should write to file in logs folder", (done) ->
			file = "../logs/test.log"
			log.writeTo file, "test"

			fs.readFile(
				"#{__dirname}/#{file}"
				"utf8"
				(err, data) ->
					expect(data).toEqual("test")
					do done
			)
		)
)

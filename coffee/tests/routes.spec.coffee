request = require 'request'

describe(
	"Routes tests"
	->
		it("should respond with error 404", (done) ->
			request("http://localhost:9999/404", (error, response, body) ->
				expect(response.statusCode).toEqual 404
				do done
			)
		)

		it("should respond with 'Получить токен'", (done) ->
			request("http://localhost:9999/", (error, response, body) ->
				expect(response.statusCode).toEqual 200
				do done
			)
		)

		it("should respond with 'Получить токен'", (done) ->
			request("http://localhost:9999/setstatus", (error, response, body) ->
				expect(response.statusCode).toEqual 200
				do done
			)
		)
)

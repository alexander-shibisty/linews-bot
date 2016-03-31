log	     = require "../helpers/logs"
date     = require "../helpers/date"
sqlite3  = do require("sqlite3").verbose
db       = new sqlite3.Database("#{__dirname}/../config/test.db")

describe(
	"SQLite tests"
	->
		it(
			"should return random row"
			(done) ->
				db.serialize(
					->
						query = "SELECT title FROM test_table WHERE published = $int ORDER BY RANDOM()"

						db.get(
							query
							$int: 0
							(error, row) ->
								check = true

								if error
									console.log error
									check = false
								else if !row
									console.log row
									check = false

								expect( check ).toEqual true
								do done
						)
				)
		)
)

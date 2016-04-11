sleep	= require "../helpers/sleep"

describe(
	"Sleep tests"
	->
		it(
			"Wait 1 second"
			(done) ->
				console.log 'sleep...'
				sleep.sleep(
					1
					->
						console.log 'wakeup'

						expect(on).toEqual on
						do done
				)
		)
)

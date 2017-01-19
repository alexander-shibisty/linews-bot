sleep	= require "../helpers/sleep"

describe(
	"Sleep tests"
	->
		it(
			"Wait 1 second"
			(done) ->
				sleepTime = (new Date()).getTime()

				sleep.sleep(
					1
					->
						wakeupTime = (new Date()).getTime()

						expect( ((wakeupTime - sleepTime) >= 1000) ).toEqual on
						do done
				)
		)
)

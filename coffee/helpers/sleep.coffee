sleep = ->
	#

module.exports =
	sleep: (s, wake) ->
		e = (new Date()).getTime() + (s * 1000)

		do sleep while (new Date()).getTime() <= e

		do wake
	usleep: (s, wake) ->
		e = (new Date()).getTime() + (s / 1000)

		do sleep while (new Date()).getTime() <= e

		do wake

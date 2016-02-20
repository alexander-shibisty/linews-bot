#return date in format "day.mouth"
module.exports.toDay = ->
	date  = new Date()
	mouth = do date.getMonth + 1
	day   = do date.getDate

	return "#{day}.#{mouth}"

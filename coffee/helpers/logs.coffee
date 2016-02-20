fs = require "fs"

module.exports.writeTo = (file, data) ->
	fs.writeFile(
		(__dirname + '/' + file),
		data,
		(err) -> if(err) then console.log err
	)

fs    	= require "fs"
http  	= require "http"
https  	= require "https"

module.exports = (image, newName, callback) ->
	path = "#{__dirname}/../images/#{newName}"

	fileExists = fs.existsSync path

	if !fileExists

		file = fs.createWriteStream path

		httpsPattern =
		/// ^
			(?:https)
		///

		protocol = if httpsPattern.test(image) then https else http

		downloadImage = protocol.get(
			image
			(response) ->
				response.pipe file

				callback null
		)
	else if fileExists then callback null

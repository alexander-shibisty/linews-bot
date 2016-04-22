fs    	= require "fs"
http  	= require "http"
https  	= require "https"

module.exports = (image, newName, callback) ->
	path = "#{__dirname}/../images/#{newName}"

	if !fs.existsSync path
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

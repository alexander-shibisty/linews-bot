imageDownloader = require "../helpers/downloadImageByUrl"
sha1 			= require "sha1"
fs              = require "fs"

describe(
	"Image download"
	->
		it(
			"Should download image from url"
			(done) ->
				image = 'http://store.akamai.steamstatic.com/public/shared/images/header/globalheader_logo.png'
				newName = sha1 image
				newName = "#{newName}.png"

				path = "#{__dirname}/../images/#{newName}"

				imageDownloader(
					image
					newName
					(error) ->
						expect( fs.existsSync path ).toEqual on

						do done
				)
		)
)

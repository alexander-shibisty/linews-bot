request = require "request"
config  = require "config"
rest  	= require "restler"
fs    	= require "fs"
http  	= require "http"
https  	= require "https"
sha1  	= require "sha1"
async 	= require "async"
log   	= require "../helpers/logs"

toLog   = (data) -> log.writeTo "logs/status.log", data

module.exports = (image, params, done) ->
	if !image
		return done "Переданы не все аргументы", null
	if !params
		return done "Переданы не все аргументы", null
	if !done
		return done "Переданы не все аргументы", null

	async.waterfall(
		[
			(callback) ->
				newName = sha1 image
				newName = "#{newName}.jpg"
				file    = fs.createWriteStream "#{__dirname}/../images/#{newName}"

				httpsPattern =
				/// ^
					(?:https)
				///i

				if httpsPattern.test(image)
					downloadImage = https.get(image
						(response) ->
							response.pipe file

							upd_url  = "https://api.vk.com/method/photos.getUploadServer"
							upd_url += "?group_id=#{params.group}"
							upd_url += "&album_id=#{params.album}"
							upd_url += "&access_token=#{params.token}"

							request(
								upd_url
								(err, head, body) ->
									if err
										toLog "Error in ImageUploader: #{err}"
										return callback err, []

									body = JSON.parse body
									callback null, newName, body
							)
					)
				else
					downloadImage = http.get(image
						(response) ->
							response.pipe file

							upd_url  = "https://api.vk.com/method/photos.getUploadServer"
							upd_url += "?group_id=#{params.group}"
							upd_url += "&album_id=#{params.album}"
							upd_url += "&access_token=#{params.token}"

							request(
								upd_url
								(err, head, body) ->
									if err
										toLog "Error in ImageUploader: #{err}"
										return callback err, []

									body = JSON.parse body
									callback null, newName, body
							)
					)
			(newName, body, callback) ->
				if body.response && body.response.upload_url
					imagePath = "#{__dirname}/../images/#{newName}"
					rest.post(
						body.response.upload_url
						multipart: true
						data:
							'file1':
								rest.file(
									imagePath
									null
									fs.statSync(imagePath).size
									null
									"image/jpg"
								)
					).on(
						'complete',
						(data) ->
							callback null, data
					)
				else
					callback "Что-то пошло не так: #{body}."
			(data, callback) ->
				if data
					data = JSON.parse data

					save_url  =  "https://api.vk.com/method/photos.save"
					save_url += "?access_token=#{params.token}"
					save_url += "&album_id=#{params.album}"
					save_url += "&group_id=#{params.group}"
					save_url += "&server=#{data.server}"
					save_url += "&photos_list=#{data.photos_list}"
					save_url += "&hash=#{data.hash}"

					rest.get(
						save_url
					).on(
						'complete',
						(res) ->
							callback null, res
					)
		]
		(err, result) ->
			if err
				return toLog "Error in ImageUploader: #{err}"

			done null, result
	)

	return;

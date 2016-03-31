request = require "request"
config  = require "config"
rest  	= require "restler"
fs    	= require "fs"
http  	= require "http"
https  	= require "https"
sha1  	= require "sha1"
async 	= require "async"
log   	= require "../helpers/logs"

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
				///

				protocol = if httpsPattern.test(image) then https else http

				downloadImage = protocol.get(image
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
									return callback "Error in ImageUploader: #{err}", []

								body = if typeof body == "object" then body else JSON.parse body
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
					body = if typeof body == 'object' then JSON.stringify body else body
					callback "Что-то пошло не так: #{body}."
			(data, callback) ->
				if data
					data = if typeof data == "object" then data else JSON.parse data

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
				return done "Error in ImageUploader: #{err}", null

			done null, result
	)

	return;

request = require "request"
config  = require "config"
rest    = require "restler"
fs      = require "fs"
http    = require "http"
sha1    = require "sha1"
async   = require "async"
log     = require "../helpers/logs"

module.exports = (images, done) ->
	if !images.length then return done null

	async.waterfall(
		[
			(callback) ->
				dowFuncs =     []
				global   =
					count    : 0
					images   : []
					newNames : []

				count = 0
				for image in images
					if count <= 4
						newName = sha1 image
						newName = "#{newName}.jpg"
						global.images.push   image
						global.newNames.push newName

						if(count == 0)
							dowFuncs.push(
								(callback) ->
									path = "#{__dirname}/../images/#{global.newNames[global.count]}"

									if !fs.existsSync path
										file = fs.createWriteStream path
										downloadImage = http.get(
											global.images[global.count]
											(response) ->
												response.pipe file
												callback null, true
										)
									else
										callback null, true

									global.count++
							)
						else
							dowFuncs.push(
								(result, callback) ->
									path = "#{__dirname}/../images/#{global.newNames[global.count]}"

									if !fs.existsSync path
										file = fs.createWriteStream path
										downloadImage = http.get(
											global.images[global.count]
											(response) ->
												response.pipe file
												callback null, true
										)
									else
										callback null, true

									global.count++
							)

					count++

				async.waterfall(
					dowFuncs
					(error, result) ->
						upd_url  = "https://api.vk.com/method/photos.getUploadServer"
						upd_url += "?group_id=#{config.common.group_id}"
						upd_url += "&album_id=#{config.common.linews_thumbnail_id}"
						upd_url += "&access_token=#{config.common.vk_token}"

						request(
							upd_url
							(err, head, body) ->
								if err
									return callback "Error in ImageUploader: #{err}", []

								body = JSON.parse body
								callback null, global.newNames, body
						)
				)
			(images, body, callback) ->

				files = {}
				count = 1

				for image in images
					imagePath = "#{__dirname}/../images/#{image}"
					files["file#{count}"] =
						rest.file(
							imagePath
							null
							fs.statSync( imagePath ).size
							null
							"image/jpg"
						)
					count++

				if body.response && body.response.upload_url
					rest.post(
						body.response.upload_url
						multipart: true
						data: files
					).on(
						'complete',
						(data) ->
							callback null, data
					)
				else
					callback "Что-то пошло не так: #{body}.", []
			(data, callback) ->
				data = JSON.parse data

				save_url  =  "https://api.vk.com/method/photos.save"
				save_url += "?access_token=#{config.common.vk_token}"
				save_url += "&album_id=#{config.common.linews_thumbnail_id}"
				save_url += "&group_id=#{config.common.group_id}"
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

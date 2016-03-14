request = require "request"
config = require "config"
rest = require "restler"
fs = require "fs"
http = require "http"
sha1 = require "sha1"
async = require "async"
log = require "../helpers/logs"

toLog   = (data) -> log.writeTo "../logs/status.log", data

module.exports = (image, done) ->
	if !image then return done null

	async.waterfall(
		[
			(callback) ->
				newName = sha1 image
				newName = "#{newName}.jpg"
				file = fs.createWriteStream("#{__dirname}/../images/#{newName}")

				downloadImage = http.get(image
					(response) ->
						response.pipe file

						upd_url = "https://api.vk.com/method/photos.getUploadServer?"
						upd_url += "group_id=#{config.common.group_id}"
						upd_url += "&album_id=#{config.common.linews_thumbnail_id}"
						upd_url += "&access_token=#{config.common.vk_token}"
						
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
				rest.post(
					body.response.upload_url
					multipart: true
					data:
						'file1': rest.file("#{__dirname}/../images/#{newName}", null, fs.statSync("#{__dirname}/../images/#{newName}").size, null, "image/jpg")
				).on(
					'complete',
					(data) ->
						callback null, data
				)
			(data, callback) ->
				data = JSON.parse data

				save_url =  "https://api.vk.com/method/photos.save"
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
				return toLog "Error in ImageUploader: #{err}"

			done result
	)

	return;

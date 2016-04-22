request         = require "request"
config          = require "config"
rest  	        = require "restler"
fs    	        = require "fs"
sha1  	        = require "sha1"
async 	        = require "async"
imageDownloader = require "../helpers/downloadImageByUrl"
log   	        = require "../helpers/logs"

module.exports = (_image, _params, _done) ->
	if !_image || typeof _image != 'string'
		return _done "Переданы не все аргументы", null
	if !_params || typeof params != 'object'
		return _done "Переданы не все аргументы", null
	if !_done || typeof _done != 'function'
		return _done "Переданы не все аргументы", null

	async.waterfall(
		[
			(callback) ->
				@newName = sha1 _image
				@newName = "#{@newName}.jpg"

				imageDownloader(
					_image
					@newName
					(error) ->
						callback null, @newName
				)
			(newName, callback) ->
				@upd_url  = "https://api.vk.com/method/photos.getUploadServer"
				@upd_url += "?group_id=#{_params.group}"
				@upd_url += "&album_id=#{_params.album}"
				@upd_url += "&access_token=#{_params.token}"

				request(
					@upd_url
					(err, head, body) ->
						if err
							return callback "Error in ImageUploader: #{err}", []

						body = if typeof body == "object" then body else JSON.parse body
						callback null, newName, body
				)
			(newName, body, callback) ->
				if body && body.response && body.response.upload_url
					@imagePath = "#{__dirname}/../images/#{newName}"
					rest.post(
						body.response.upload_url
						multipart: true
						data:
							'file1':
								rest.file(
									@imagePath
									null
									fs.statSync(@imagePath).size
									null
									"image/jpg"
								)
					).on(
						'complete',
						(data) ->
							data = if typeof data == "object" then data else JSON.parse data

							callback null, data
					)
				else
					callback "Что-то пошло не так: #{body}."
			(data, callback) ->
				if data && data.server && data.photos_list && data.hash
					@save_url  =  "https://api.vk.com/method/photos.save"
					@save_url += "?access_token=#{_params.token}"
					@save_url += "&album_id=#{_params.album}"
					@save_url += "&group_id=#{_params.group}"
					@save_url += "&server=#{data.server}"
					@save_url += "&photos_list=#{data.photos_list}"
					@save_url += "&hash=#{data.hash}"

					rest.get(
						@save_url
					).on(
						'complete',
						(res) ->
							callback null, res
					)
				else
					callback "Ошибка API", []
		]
		(err, result) ->
			if err
				return _done "Error in ImageUploader: #{err}", null

			_done null, result
	)

	return;

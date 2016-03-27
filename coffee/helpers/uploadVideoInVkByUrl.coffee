request = require "request"
config  = require "config"
async   = require "async"
log     = require "../helpers/logs"

module.exports = (video, done) ->
	save_url  = "https://api.vk.com/method/video.save"
	save_url += "?access_token=#{config.common.vk_token}"
	save_url += "&name=#{video['name']}"
	save_url += "&wallpost=0"
	save_url += "&link=https://www.youtube.com/watch?v=#{video['id']}"
	save_url += "&group_id=#{config.common.group_id}"
	save_url += "&album_id=#{config.common.video_album}"
	save_url += "&repeat=0"

	request(
		save_url
		(err, head, body) ->
			if err
				return done err, null

			if !body
				return done "Отсутствуют данные.", null


			json = if typeof body == "object" then body else JSON.parse body

			if json.response && json.response.upload_url
				request json.response.upload_url, (err, head, body) -> done json
			else
				done "Ошибка API: #{body}", null
	)

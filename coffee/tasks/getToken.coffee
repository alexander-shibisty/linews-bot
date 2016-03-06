request = require "request"
config = require "config"
log = require "../helpers/logs"

module.exports = (req, res) ->
	url = "https://oauth.vk.com/authorize?client_id=#{config.common.group_id}&scope=status,photos,wall,offline&v=5.45&response_type=token"

	res.send(
		"<a href=\"#{url}\">Получить токен</a>"
	)

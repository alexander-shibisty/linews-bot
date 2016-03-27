request = require "request"
config = require "config"
log = require "../helpers/logs"

module.exports = (req, res) ->
	captcha_sid = 283067411569
	captcha_key = "spmeus"
	url = "https://api.vk.com/method/wall.get?domain=linewson&count=1&captcha_sid=#{captcha_sid}&captcha_key=#{captcha_key}"

	res.send(
		"<a href=\"#{url}\">Убить каптчу</a>"
	)

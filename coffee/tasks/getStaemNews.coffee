request = require "request"
config = require "config"
log = require "../helpers/logs"
async = require "async"

uploadImageInVk = require "../helpers/uploadImageInVk"

toLog   = (data) -> log.writeTo "../logs/status.log", data

module.exports = (req, res) ->
	async.waterfall(
		[
			(callback) ->
				steam = "http://store.steampowered.com/?cc=ru"
				request(
					steam
					(err, head, body) ->
						if err
							toLog "Error in first query: #{err}"
							callback err, []
						else
							callback null, body
				)
			(body, callback) ->
				env = require("jsdom").env
				html = body

				env(
					html
					(errors, window) ->
						if errors then toLog errors

						$ = require("jquery")(window)
						image = $("#spotlight_scroll").children("div").find(".spotlight_img a img").attr("src")

						callback null, image
				)
			(image, callback) ->
				uploadImageInVk image, (result) -> callback null, result
		]
		(err, result) ->
			console.log result
	)

	do res.end

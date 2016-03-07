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
						if errors then toLog "Error in HTML Parser: #{errors}"

						$ = require("jquery")(window)
						image = $("#spotlight_scroll").children("div").find(".spotlight_img a img").attr("src")
						discount = $($("#spotlight_scroll").find(".spotlight_content .discount_pct")[0]).text()
						count = $($("#spotlight_scroll").find(".spotlight_content .discount_final_price")[0]).text()
						#text = $($("#spotlight_scroll").find(".spotlight_content .spotlight_body[class!='price']")[0]).text()
						link = $("#spotlight_scroll").children("div").find(".spotlight_img a").attr("href")

						callback null, image, discount, count, link
				)
			(image, discount, count, link, callback) ->
				uploadImageInVk(
					image,
					(result) ->
						response = []

						response.push "photo-#{config.common.group_id}_#{result.response[0].pid}"
						response.push discount
						response.push count
						#response.push text
						response.push link

						callback null, response
				)
		]
		(err, result) ->
			if err
				toLog "Error in last async method: #{err}"

			str = encodeURIComponent "Акция на выходных в Steam.\n Скидка #{result[1]}, покупка обойдется в #{result[2]}."
			last_url = "https://api.vk.com/method/wall.post?"
			last_url += "owner_id=-#{config.common.group_id}"
			last_url += "&attachments=#{result[0]},#{result[3]}"
			last_url += "&message=#{str}"
			last_url += "&from_group=1"
			last_url += "&access_token=#{config.common.vk_token}"

			# request(
			# 	last_url
			# 	(err, head, body) ->
			# 		if err then toLog err
			#
			# 		toLog body
			# )
	)

	do res.end

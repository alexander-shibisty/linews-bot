request          = require "request"
config           = require "config"
log              = require "../helpers/logs"
async            = require "async"

uploadImagesInVk = require "../helpers/uploadImagesInVkByUrls"

toLog            = (data) -> log.writeTo "logs/steam.log", data

module.exports = (req, res) ->
	async.waterfall(
		[
			(callback) ->
				steam = "http://store.steampowered.com/?cc=ru"
				request(
					steam
					(err, head, body) ->
						if err
							callback "Error in first query: #{err}", ""
						else
							callback null, body
				)
			(html, callback) ->
				env = require("jsdom").env

				env(
					html
					(errors, window) ->
						if errors then return callback "Error in HTML Parser: #{errors}", []

						$ = require("jquery")(window)
						images = $("#spotlight_scroll").children("div").find(".spotlight_img a img")
						result = []

						for image in images
							discount = $(image).parents(".home_area_spotlight").find(".spotlight_content .discount_pct").text()
							count    = $(image).parents(".home_area_spotlight").find(".spotlight_content .discount_final_price").text()
							link     = $(image).parents(".home_area_spotlight").find(".spotlight_img a").attr("href")

							if link
								result.push
									image    : $(image).attr 'src'
									discount : discount ? discount : null
									count	 : count    ? count    : null
									link	 : link

						if result.length
							callback null, result
						else
							callback "Недостаточно данных", []
				)
			(result, callback) ->
				images = []

				for item in result
					images.push item.image

				uploadImagesInVk(
					images,
					(error, downDone) ->
						if error then return callback error, []

						if downDone.response && downDone.response.length
							count = 0

							for imageItem in downDone.response
								result[ count ].image = "photo-#{config.common.group_id}_#{imageItem.pid}"
								count++

							callback null, result
						else
							callback "Не удалось загрузить картинки", []
				)
		]
		(error, result) ->
			if error
				return toLog "Error: #{error}"

			post = "Сейчас в Steam:\n"
			attachments = ""
			count = 1

			for item in result
				attachments += "#{item.image},"

				post += "#{count++}. Акция на выходных в Steam.\n"

				if item.discount
					post += "Скидка #{item.discount}"
					post += ", покупка обойдется в #{item.count}\n"

				post += "Получить можно по ссылке: #{item.link}\n\n"

			post += "#lnGames"
			post  = encodeURIComponent post

			last_url = "https://api.vk.com/method/wall.post"
			last_url += "?owner_id=-#{config.common.group_id}"
			last_url += "&attachments=#{attachments}https://steampowered.com/"
			last_url += "&message=#{post}"
			last_url += "&from_group=1"
			last_url += "&access_token=#{config.common.vk_token}"

			request(
				last_url
				(err, head, body) ->
					if err then toLog "Error in last request: #{err}"

					toLog body
			)
	)

	do res.end

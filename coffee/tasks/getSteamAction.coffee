request = require "request"
config = require "config"
log = require "../helpers/logs"

toLog   = (data) -> log.writeTo "../logs/status.log", data

module.exports = (req, res) ->
	steam = "http://store.steampowered.com/?cc=ru"
	request(
		steam
		(err, head, body) ->
			env = require("jsdom").env
			html = body

			env(html, (errors, window) ->
				if errors then toLog errors

				$ = require("jquery")(window)
				post = ""

				$("#tab_specials_content").children("div").each(
					(index, element) ->
						element = $(element)
						title = do element.find(".tab_item_name").text
						link = element.find("a").attr "href"
						count = do element.find(".discount_final_price").text
						discount = do element.find(".discount_pct").text

						if title && link && count && discount
							post += "Скидка #{discount} на #{title}, покупка обойдется в #{count}\n#{link}\n\n"
				)

				if post
					start = "Сегодня в Steam:\n\n"
					end = "#lnGames #BotArseny"
					post = "#{start} #{post} #{end}"

					str = encodeURIComponent post
					last_url = "https://api.vk.com/method/wall.post?"
					last_url += "owner_id=-#{config.common.group_id}"
					last_url += "&message=#{str}"
					last_url += "&from_group=1"
					last_url += "&attachments=#{steam}"
					last_url += "&access_token=#{config.common.vk_token}"

					request(
						last_url
						(err, head, body) ->
							if err then toLog err

							toLog body
					)

				do res.end
			)
	)

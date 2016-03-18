#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
async = require "async"
sqlite3 = do require("sqlite3").verbose

toLog   = (data) -> log.writeTo "../logs/instagram.log", data

module.exports = (req, res) ->
	db = new sqlite3.Database("#{__dirname}/../config/instagram.db")
	db.serialize( ->
		db.each(
			"SELECT rowid AS id, channel_id FROM #{config.database.instagram_accounts} ORDER BY date ASC LIMIT $limit"
			$limit: 3
			(error, row) ->
				if error then return toLog "SQLite Error: #{error}"

				unless row.length then return toLog "Аккаунты не найдены"

				async.waterfall(
					[
						(callback) ->
							db.get(
								"SELECT post_id FROM published WHERE channel_id = #{row.channel_id} ORDER BY date LIMIT 1"
								(error, item) ->
									if error then return callback "Ошибка запроса: #{error}", null
									console.log item
									callback null, item.post_id
							)
						(last_id, callback) ->
							get_url  = "https://api.instagram.com/v1/users/"
							get_url += "#{row.channel_id}/media/recent/"
							get_url += "?access_token=#{config.common.inst_token}"
							get_url += "&count=1"
							get_url += "&min_id=#{last_id}"

							request(
								get_url
								(error, head, body) ->
									if error then return callback "Ошибка Inst API: #{error}", []
									json   = JSON.parse body
									data   = json.data
									result = []

									for item in data
										unless item.id == last_id
											result.push
												image: item.images.standard_resolution.url
												id: item.id

									callback null, result
							)
						(result, callback) ->
							db.get(
								"SELECT post_id FROM #{config.database.instagram_published} WHERE link = $link LIMIT 1"
								$link: result.id
								(error, row) ->
									if !error && !row
										callback null, result
									else if error
										callback "Ошибка запроса: #{error}", []
									else
										callback "Вероятно, пост уже был", []
							)
						(result, callback) ->
							unless result.length then return callback "Нет данных", [], []

							uploadImageInVk(
								result[0].image
								group: config.common.group_id
								album: config.common.linews_thumbnail_id
								token: config.common.vk_token
								(error, data) ->
									if error then return callback error, []

									callback null, result, data
							)
					]
					(error, result, upload) ->
						if error
							do db.close
							return toLog "Error: #{error}"
						unless result.length
							do db.close
							return toLog "Нет данных"
						unless upload
							do db.close
							return toLog "Нет данных"

						date = (new Date()).getTime()
						ins_query  = "INSERT INTO #{config.database.instagram_published} (date, link, post_id, channel_id) "
						ins_query += "VALUES($date, $link, $post_id, $channel_id)"

						db.run(
							ins_query
							$date : date
							$link : result[0].image
							$post_id : result[0].id
							$channel_id: row.channel_id
							(error) ->
								if error then toLog error

								post = "#instagram #lnGames"
								post = encodeURIComponent post

								post_url = "https://api.vk.com/method/wall.post?"
								post_url += "owner_id=-#{config.common.group_id}"
								post_url += "&message=#{post}"
								post_url += "&from_group=1"
								post_url += "&attachments=photo-#{config.common.group_id}_#{upload.response[0].pid}"
								post_url += "&access_token=#{config.common.vk_token}"

								request(
									post_url,
									(err, head, body) ->
										toLog body
								)

								do db.close
						)
				)
		)

		do res.end
	)

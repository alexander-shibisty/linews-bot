#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
async = require "async"
sqlite3 = do require("sqlite3").verbose
uploadImageInVk = require "../helpers/uploadImageInVk"

toLog   = (data) -> log.writeTo "../logs/DeAnna.log", data

module.exports = (req, res) ->
	db = new sqlite3.Database("#{__dirname}/../config/DeAnna.db")
	db.serialize( ->
		async.waterfall(
			[
				(callback) ->
					db.get(
						"SELECT post_id FROM published ORDER BY date LIMIT 1"
						(error, row) ->
							if error then return callback "Ошибка запроса: #{error}", null

							callback null, row.post_id
					)
				(last_id, callback) ->
					get_url  = "https://api.instagram.com/v1/users/"
					get_url += "#{config.common.DeAnna_inst}/media/recent/"
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
						"SELECT post_id FROM published WHERE link = $link LIMIT 1"
						$link: result.image
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
						group: config.common.DeAnna_group
						album: config.common.DeAnna_album
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
				ins_query  = "INSERT INTO #{config.database.DeAnna_published_table} (date, link, post_id) "
				ins_query += "VALUES($date, $link, $post_id)"

				db.run(
					ins_query
					$date : date
					$link : result[0].image
					$post_id : result[0].id
					(error) ->
						if error then toLog error

						post = "#instagram #DeannaDavis #ItsRainingNeon"
						post = encodeURIComponent post

						post_url = "https://api.vk.com/method/wall.post?"
						post_url += "owner_id=-#{config.common.DeAnna_group}"
						post_url += "&message=#{post}"
						post_url += "&from_group=1"
						post_url += "&attachments=photo-#{config.common.DeAnna_group}_#{upload.response[0].pid}"
						post_url += "&access_token=#{config.common.vk_token}"

						request(
							post_url,
							(err, head, body) ->
								toLog body
						)

						do db.close
				)
		)

		do res.end
	)

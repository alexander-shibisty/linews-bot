request		    = require "request"
config		    = require "config"
log			    = require "../helpers/logs"
async		    = require "async"
sqlite3		    = do require("sqlite3").verbose
uploadImageInVk = require "../helpers/uploadImageInVkByUrl"
db			    = new sqlite3.Database("#{__dirname}/../config/cosplays.db")
sleep           = require "../helpers/sleep"

toLog		   = (data) -> log.writeTo "logs/cosplays.log", data

module.exports = (req, res) ->
	accountsTable  = config.database.instagram_accounts
	publishedTable = config.database.instagram_published

	groupId   = config.cosplays.group_id
	albumId   = config.cosplays.album_id
	vkToken   = config.common.vk_token
	instToken = config.common.inst_token

	db.serialize( ->
		db.each(
			"SELECT rowid AS id, channel_id FROM #{accountsTable} ORDER BY date ASC LIMIT $limit"
			$limit: 3
			(error, row) ->
				if error
					return toLog "SQLite Error: #{error}"

				unless row.id
					return toLog "Аккаунты не найдены"

				async.waterfall(
					[
						(callback) ->
							db.get(
								"SELECT post_id FROM #{publishedTable} WHERE channel_id = $id ORDER BY date LIMIT 1"
								$id: row.channel_id
								(error, item) ->
									if error then return callback "Ошибка запроса: #{error}", null

									list_id = if item then item.post_id else 0
									callback null, list_id
							)
						(last_id, callback) ->
							get_url  = "https://api.instagram.com/v1/users/"
							get_url += "#{row.channel_id}/media/recent/"
							get_url += "?access_token=#{instToken}"
							get_url += "&count=1"
							get_url += "&min_id=#{last_id}"

							request(
								get_url
								(error, head, body) ->
									if error then return callback "Ошибка Inst API: #{error}", []
									json   = if typeof body == "object" then body else JSON.parse body
									data   = json.data
									result = []

									for item in data
										unless item.id == last_id
											result.push
												image: item.images.standard_resolution.url
												id: item.id
												username: item.user.username

									callback null, result
							)
						(result, callback) ->
							unless result.length then return callback "Недостаточно данных.", []

							if result[0] && result[0].id
								db.get(
									"SELECT link FROM #{publishedTable} WHERE post_id = $post_id LIMIT 1"
									$post_id: result[0].id
									(error, item) ->

										if error
											callback "Ошибка запроса: #{error}", []
										else if item
											callback "Вероятно, пост уже был", []
										else if !item
											callback null, result
								)
							else callback "Недостаточно данных.", []
						(result, callback) ->
							unless result.length then return callback "Нет данных", [], []

							uploadImageInVk(
								result[0].image
								group: groupId
								album: albumId
								token: vkToken
								(error, data) ->
									if error then return callback error, []

									callback null, result, data
							)
					]
					(error, result, upload) ->
						if error
							return toLog "Error: #{error}"
						unless result.length
							return toLog "Нет данных"
						unless upload
							return toLog "Нет данных"

						date = (new Date()).getTime()

						if result[0]
							image	   = result[0].image	    || null
							id		   = result[0].id		    || null
							username   = result[0].username	    || null

						if row
							channel_id = row.channel_id		    || null

						if upload && upload.response && upload.response.length && upload.response[0]
							pid		   = upload.response[0].pid || null

						if channel_id
							db.run(
								"UPDATE #{accountsTable} SET date = $date WHERE channel_id = $channel_id"
								$date: date
								$channel_id: channel_id
								(error) ->
									if error then "Error in update: #{error}"
							)

						ins_query  = "INSERT INTO #{publishedTable} (date, link, post_id, channel_id) "
						ins_query += "VALUES($date, $link, $post_id, $channel_id)"
						if image && id && username && channel_id && pid
							db.run(
								ins_query
								$date : date
								$link : image
								$post_id : id
								$channel_id: channel_id
								(error) ->
									if error then toLog error

									post = "#instagram ##{username}"
									post = encodeURIComponent post

									post_url = "https://api.vk.com/method/wall.post"
									post_url += "?owner_id=-#{groupId}"
									post_url += "&message=#{post}"
									post_url += "&from_group=1"
									post_url += "&attachments=photo-#{groupId}_#{pid}/"
									post_url += "&access_token=#{vkToken}"

									request(
										post_url,
										(err, head, body) ->
											toLog body
									)
							)
				)

				sleep.sleep 60, -> toLog "Итерация готова!"
		)

		do res.end
	)

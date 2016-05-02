request = require "request"
config  = require "config"
sqlite3 = do require("sqlite3").verbose
async   = require "async"
log     = require "../helpers/logs"

db      = new sqlite3.Database("#{__dirname}/../config/alligator.db")

toLog   = (data) -> log.writeTo "logs/eubrim.log", data

module.exports = (req, res) ->

	posts = config.eubrim.database.posts_table

	query  = "SELECT rowid AS id, post "
	query += "FROM #{posts} "
	query += "WHERE published ISNULL "
	query += "ORDER BY RANDOM()"

	db.serialize( ->
		db.get(
			query
			(error, row) ->
				if error then return toLog "Ошибка запроса к db: #{error}"
				unless row then return toLog "Не найден пост"

				post = row.post

				if post
					async.waterfall(
						[
							(callback) ->
								post_url = "https://api.vk.com/method/wall.post"
								post_url += "?owner_id=-#{config.eubrim.group_id}"
								post_url += "&message="
								post_url += "&from_group=1"
								post_url += "&attachments=#{post}"
								post_url += "&access_token=#{config.common.vk_token}"

								request(
									post_url,
									(err, head, body) ->
										if err then return callback "Ошибка в запросе к API: #{err}", []

										callback null, body
								)
						]
						(error, result) ->
							if error then return "Ошибка в результате: #{error}"

							db.run(
								"UPDATE #{posts} SET published = $published WHERE post = $post"
								$published: '1'
								$post: post
								(error) ->
									if error then "Error in update: #{error}"
							)

							toLog "Пост отправлен: #{result}"
					)
		)
	)

	do res.end

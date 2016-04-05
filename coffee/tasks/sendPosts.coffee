request = require "request"
config  = require "config"
sqlite3 = do require("sqlite3").verbose
async   = require "async"
log     = require "../helpers/logs"

db      = new sqlite3.Database("#{__dirname}/../config/alligator.db")

toLog   = (data) -> log.writeTo "logs/alligator.log", data

module.exports = (req, res) ->

	posts = config.alligator.database.posts_table
	query  = "SELECT rowid AS id, post "
	query += "FROM #{posts} "
	query += "WHERE published ISNULL OR published = '' "
	query += "ORDER BY RANDOM() "
	query += "LIMIT $limit"

	db.serialize( ->
		db.each(
			query
			$limit: 1
			(error, row) ->
				if error then return toLog "Ошибка запроса к db: #{error}"
				unless row.post then return toLog "Не найден пост"

				post = row.post

				if post
					async.waterfall(
						[
							(callback) ->
								post_url = "https://api.vk.com/method/wall.post"
								post_url += "?owner_id=-#{config.alligator.group_id}"
								post_url += "&message="
								post_url += "&from_group=1"
								post_url += "&attachments=#{post}"
								post_url += "&access_token=#{config.common.vk_token}"

								request(
									post_url,
									(err, head, body) ->
										if err then return toLog "Ошибка в запросе к API: #{err}"

										callback null, body
								)
						]
						(error, result) ->
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
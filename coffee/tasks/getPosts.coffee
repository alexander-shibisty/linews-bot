request = require "request"
config  = require "config"
sqlite3 = do require("sqlite3").verbose
async   = require "async"
log     = require "../helpers/logs"
sleep   = require "../helpers/sleep"

db      = new sqlite3.Database("#{__dirname}/../config/alligator.db")

toLog   = (data) -> log.writeTo "logs/alligator.log", data

module.exports = (req, res) ->
	db.serialize( ->
		db.each(
			"SELECT rowid AS id, domain FROM #{config.alligator.database.groups_table} ORDER BY date ASC LIMIT $limit"
			$limit: 3
			(error, row) ->
				if error then return toLog "Ошибка запроса к db: #{error}"
				unless row.domain then return toLog "Нет необходимого параметра"

				domain = row.domain

				if domain
					async.waterfall(
						[
							(callback) ->
								url = "https://api.vk.com/method/wall.get?domain=#{domain}&count=10"

								request(
									url
									(error, head, body) ->
										if error then return callback 'Ошибка запроса к API', []

										json = if typeof body == "object" then body else JSON.parse body
										posts = []

										for post in json.response
											if typeof post == 'object' && !post.is_pinned && post.text == '' && post.attachments && post.attachments.length == 1
												item = if post.attachments[0] then post.attachments[0] else {}

												if item.type == 'photo' && item.photo.pid && item.photo.owner_id
													posts.push
														image: "photo#{item.photo.owner_id}_#{item.photo.pid}"

										callback null, posts
								)
							(posts, callback) ->
								unless posts.length then return toLog "Недостаточно данных", []
								count = 0
								functions = []
								global.images = []
								global.count = 0
								global.check = []

								for post in posts
									global.images.push post.image

								for post in posts
									if count == 0
										functions.push(
											(done) ->
												db.get(
													"SELECT rowid FROM #{config.alligator.database.posts_table} WHERE post = $post"
													$post: global.images[global.count]
													(error, row) ->
														if error
															return toLog "Ошибка выборки: #{error}"
														if row
															return toLog "Такой пост уже есть"
														if !row
															global.check.push global.images[global.count]

														global.count++
														done null, true
												)


										)
									else
										functions.push(
											(result, done) ->
												db.get(
													"SELECT rowid FROM #{config.alligator.database.posts_table} WHERE post = $post"
													$post: global.images[global.count]
													(error, row) ->
														if error
															return toLog "Ошибка выборки: #{error}"
														if row
															return toLog "Такой пост уже есть"
														if !row
															global.check.push global.images[global.count]

														global.count++
														done null, true
												)


										)

									count++

								async.waterfall(
									functions
									(error, result) ->
										callback null, global.check
								)
								return
						]
						(error, result) ->
							if error
								return toLog "Error: #{error}"
							unless result.length
								return toLog "Пустой массив"

							date = (new Date()).getTime()
							db.run(
								"UPDATE #{config.alligator.database.groups_table} SET date = $date WHERE domain = $domain"
								$date: date
								$domain: domain
								(error) ->
									if error then "Error in update: #{error}"
							)

							functions = []
							global.images = result
							global.count = 0
							count = 0

							for image in result
								if count == 0
									functions.push(
										(done) ->
											date = (new Date()).getTime()

											db.run(
												"INSERT INTO #{config.alligator.database.posts_table} (date, post) VALUES ($date, $post)"
												$date: date
												$post: global.images[global.count]
												(error, row) ->
													if error then toLog "Ошибка записи: #{error}"

													global.count++
													done null, true
											)
									)
								else
									functions.push(
										(data, done) ->
											date = (new Date()).getTime()

											db.run(
												"INSERT INTO #{config.alligator.database.posts_table} (date, post) VALUES ($date, $post)"
												$date: date
												$post: global.images[global.count]
												(error, row) ->
													if error then toLog "Ошибка записи: #{error}"

													global.count++
													done null, true
											)
									)

								count++


							async.waterfall(
								functions
								(error, result) ->
									toLog "Сбор завершен"
							)
					)

				sleep.sleep 60, -> toLog "Итерация готова!"
		)
	)

	do res.end

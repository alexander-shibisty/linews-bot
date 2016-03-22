#work in progress
request         = require "request"
config          = require "config"
sqlite3         = do require("sqlite3").verbose
async           = require "async"
Twitter         = require 'twitter'
log             = require "../helpers/logs"
uploadImageInVk = require "../helpers/uploadImageInVkByUrl"

db              = new sqlite3.Database("#{__dirname}/../config/twitter.db")

toLog           = (data) -> log.writeTo "logs/twitter.log", data

module.exports = (req, res) ->

	db.serialize( ->
		#db.run("CREATE TABLE channels (id, link, date)");
		#db.run("CREATE TABLE published (id, video_link, date)");
		db.each(
			"SELECT rowid AS id, user_name FROM #{config.twitter.database.accounts_table} ORDER BY date ASC LIMIT $limit"
			$limit: 1
			(error, row) ->
				if error
					return toLog "SQLite Error: #{error}"
				unless row
					return toLog "В базе нет аккаунтов"

				if row && row.user_name
					async.waterfall(
						[
							(callback) ->
								client = new Twitter
									consumer_key: config.twitter.consumer_key
									consumer_secret: config.twitter.consumer_secret
									access_token_key: config.twitter.access_token_key
									access_token_secret: config.twitter.access_token_secret

								params =
									screen_name: row.user_name
									count: 1

								client.get(
									'statuses/user_timeline'
									params
									(error, tweets, response) ->
										if error then return callback "Ошибка в twitter api : #{error}", []

										unless tweets.length then return callback "Нет данных от API", []

										tweet = tweets[0]

										if tweet.retweeted == false
											callback null, tweet
										else
											callback "Пост был не оригинальным", []
								)
							(tweet, callback) ->
								unless typeof tweet == "object" then return callback "Нет данных от API 1", []

								db.get(
									"SELECT rowid AS id, user_name FROM #{config.twitter.database.published_table} WHERE user_name = $user_name AND post_id = $post_id"
									$user_name: row.user_name
									$post_id: tweet.id
									(error, row) ->
										if error
											callback "Ошибка в запросе: #{error}", []
										else if row
											callback "Вероятно пост уже был", []
										else if !error && !row
											callback null, tweet
								)
							(tweet, callback) ->
								unless typeof tweet == "object" then return callback "Нет данных от API 2", []

								text = if tweet.text then "#{tweet.text}\n\n#lnGames" else "#lnGames"
								text = encodeURIComponent text

								response =
									text: text
									post_id: tweet.id
									userName: row.user_name
									image: null

								if tweet.entities && tweet.entities.media.length && tweet.entities.media[0].media_url
									image = tweet.entities.media[0].media_url

									uploadImageInVk(
										image
										group: config.common.group_id
										album: config.common.linews_thumbnail_id
										token: config.common.vk_token
										(error, data) ->
											if error then return callback "Не удалась загрузка картинки: #{error}", response

											if data && data.response && data.response.length
												pid = data.response[0].pid || null

												if pid
													response.image = "photo-#{config.common.group_id}_#{pid}"

													callback null, response
											else
												callback "Не удалась загрузка картинки: #{error}", response
									)
								else
									callback null, response
						]
						(error, result) ->
							if error
								return toLog "Error: #{error}"
							unless typeof result == "object"
								return toLog "Нет данных"

							date = (new Date()).getTime()
							text = result.text
							post_id = result.post_id
							userName = result.userName
							image = unless result.image == null then result.image else ''

							db.run(
								"UPDATE #{config.twitter.database.accounts_table} SET date = $date WHERE user_name = $user_name"
								$date: date
								$user_name: userName
								(error) ->
									if error then toLog "Error in update: #{error}"
							)

							if text
								ins_query  = "INSERT INTO #{config.twitter.database.published_table} (date, user_name, post_id) "
								ins_query += "VALUES($date, $user_name, $post_id)"

								db.run(
									ins_query
									$date: date
									$user_name: userName
									$post_id: post_id
									(error) ->
										if error then toLog "Ошибка записи: #{error}"

										post = "Из официального твиттера разработчиков, #{userName}.\n\n"
										post = encodeURIComponent post

										post_url =  "https://api.vk.com/method/wall.post"
										post_url += "?owner_id=-#{config.common.group_id}"
										post_url += "&message=#{post}#{text}"
										post_url += "&from_group=1"
										post_url += "&attachments=#{image}/"
										post_url += "&access_token=#{config.common.vk_token}"
										
										request(
											post_url,
											(err, head, body) ->
												toLog body
										)
								)
					)
		)

		do res.end
	)

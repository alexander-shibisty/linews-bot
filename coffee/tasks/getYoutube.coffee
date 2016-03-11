#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
sqlite3 = do require("sqlite3").verbose
uploadVideo = require "../helpers/uploadVideoInVkByLink"
async = require "async"
db = new sqlite3.Database("#{__dirname}/../config/youtube.db")

toLog   = (data) -> log.writeTo "../logs/youtube.log", data

module.exports = (req, res) ->
	db.serialize( ->
		#db.run("CREATE TABLE channels (id, link)");
		#db.run("CREATE TABLE published (id, video_link, date)");
		db.each(
			"SELECT rowid AS id, link FROM #{config.database.youtube_channels_table} LIMIT 3"
			(error, row) ->
				if error then toLog "SQLite Error: #{error}"

				if row && row.link
					async.waterfall(
						[
							(callback) ->
								url  = "https://www.googleapis.com/youtube/v3/search"
								url += "?key=#{config.common.yt_apikey}"
								url += "&channelId=#{row.link}"
								url += "&part=snippet,id&order=date"
								url += "&maxResults=1"

								request(
									url
									(err, head, body) ->
										if err
											return toLog "YT Error: #{err}"

										json = JSON.parse body
										items = json.items

										if items[0].id.videoId && items[0].snippet.title
											item = []
											item['id'] = items[0].id.videoId
											item['name'] = encodeURIComponent(items[0].snippet.title)

											callback null, item
										else
											callback 'Не хватает данных', null
								)
							(item, callback) ->
								if !item['id'] && !item['name'] then return callback 'Не хватает данных', null

								db.get(
									"SELECT rowid AS id, link FROM #{config.database.youtube_published_table} WHERE link = 'https://www.youtube.com/watch?v=#{item['id']}'"
									(error, row) ->
										if !row && !error
											uploadVideo(
												item
												(data) ->
													response = []
													response.push item
													response.push data

													callback null, response
											)
										else if !error
											callback "Ошибка запроса, #{error}", null
										else
											callback "Вероятно пост уже был, #{error}", null
								)
						]
						(error, result) ->
							if result && result.length
								date = (new Date()).getDate()
								item = result[0]
								data = result[1]

								db = new sqlite3.Database("#{__dirname}/../config/youtube.db")
								db.serialize(
									->
										query = "INSERT INTO #{config.database.youtube_published_table} (date, link) "
										query += "VALUES('#{date}', 'https://www.youtube.com/watch?v=#{item['id']}')"
										db.run query

										str = "#{item['name']}\n #lnGames"
										last_url = "https://api.vk.com/method/wall.post?"
										last_url += "owner_id=-#{config.common.group_id}"
										last_url += "&attachments=video#{data.response.owner_id}_#{data.response.vid}"
										last_url += "&message=#{str}"
										last_url += "&from_group=1"
										last_url += "&access_token=#{config.common.vk_token}"

										request(
											last_url
											(err, head, body) ->
												if err then toLog err

												toLog body
										)
								)
					)
		)
	)

	do res.end
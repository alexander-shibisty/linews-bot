request     = require "request"
config      = require "config"
log         = require "../helpers/logs"
sqlite3     = do require("sqlite3").verbose
uploadVideo = require "../helpers/uploadVideoInVkByUrl"
async       = require "async"
db          = new sqlite3.Database("#{__dirname}/../config/youtube.db")

toLog       = (data) -> log.writeTo "logs/youtube.log", data


module.exports = (req, res) ->

	db.serialize( ->
		#db.run("CREATE TABLE channels (id, link, date)");
		#db.run("CREATE TABLE published (id, video_link, date)");
		db.each(
			"SELECT rowid AS id, link FROM #{config.database.youtube_channels_table} ORDER BY date ASC LIMIT $limit"
			$limit: 1
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

										json = if typeof body == "object" then body else JSON.parse body
										items = json.items || []

										videoId = if items[0] then items[0].id.videoId    else null
										title   = if items[0] then items[0].snippet.title else null

										if videoId && title
											item = []
											item['id'] = videoId
											item['name'] = encodeURIComponent("#{title}\n #lnGames@linewson #BotArseny@linewson")

											callback null, item
										else
											callback 'Не хватает данных', null
								)
							(item, callback) ->
								if !item['id'] || !item['name'] then return callback 'Не хватает данных', null

								db.get(
									"SELECT rowid AS id, link FROM #{config.database.youtube_published_table} WHERE link = $link"
									$link: "https://www.youtube.com/watch?v=#{item['id']}"
									(error, row) ->
										if error
											return callback "Ошибка запроса, #{error}", null

										if row
											return callback "Вероятно, пост уже был", null

										if !row && !error
											uploadVideo(
												item
												(error, data) ->
													if error
														return callback "Не удалась загрузка. #{error}", null

													response = []
													response.push item
													response.push data

													callback null, response
											)
								)

								return
						]
						(error, result) ->
							date = (new Date()).getTime()

							db.run(
								"UPDATE #{config.database.youtube_channels_table} SET date = $date WHERE link = $link"
								$date: date
								$link: row.link
								(error) ->
									if error then "Error in update: #{error}"
							)

							if(error)
								error = if typeof error == 'object' then JSON.stringify error else error
								return toLog "Error in last callback: #{error}"
							else if result && result.length >= 2
								item = result[0] || []
								data = result[1] || []

								id       = item['id'] || null
								owner_id = data.response.owner_id || null
								vid      = data.response.vid || null

								ins_query  = "INSERT INTO #{config.database.youtube_published_table} (date, link) "
								ins_query += "VALUES($date, $link)"

								if id && owner_id && vid
									db.run(
										ins_query
										$date: date
										$link: "https://www.youtube.com/watch?v=#{item['id']}"
										(error) ->
											#do db.close
											if error then toLog "Error in insert: #{error}"
									)

									str = "#{item['name']}"
									#str = encodeURIComponent str
									last_url  = "https://api.vk.com/method/wall.post"
									last_url += "?access_token=#{config.common.vk_token}"
									last_url += "&owner_id=-#{config.common.group_id}"
									last_url += "&attachments=video#{owner_id}_#{vid}"
									last_url += "&message=#{str}"
									last_url += "&from_group=1"

									request(
										last_url
										(err, head, body) ->
											if err then return toLog err

											return toLog body
									)
					)
		)
	)

	do res.end

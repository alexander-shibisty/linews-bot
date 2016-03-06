#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
sqlite3 = do require("sqlite3").verbose

toLog   = (data) -> log.writeTo "../logs/youtube.log", data

module.exports = (req, res) ->

	db = new sqlite3.Database("#{__dirname}/../config/youtube.db")
	# db.serialize( ->
	# 	db.get(
	# 		"SELECT rowid AS id, status, date FROM #{config.database.youtube_channels_table} WHERE date = '#{today}'"
	# 		(error, row) ->
	# 			if error then toLog "SQLite Error: #{error}"
	#
	# 			if row && row.url
	url  = "https://www.googleapis.com/youtube/v3/search"
	url += "?key=#{config.common.yt_apikey}"
	url += "&channelId=UCCkxMbfZ80VFwwiRlIG5P5g"
	url += "&part=snippet,id&order=date"
	url += "&maxResults=3"

	request(
		url
		(err, head, body) ->
			if err
				return toLog "YT Error: #{err}"

			json = JSON.parse body
			items = json.items

			for item in items
				console.log item

			res.send items
	)
	# 	)
	# )

	do db.close
	#do res.end

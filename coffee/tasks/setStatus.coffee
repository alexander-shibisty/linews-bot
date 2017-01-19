request = require "request"
config  = require "config"
log     = require "../helpers/logs"
date    = require "../helpers/date"
sqlite3 = do require("sqlite3").verbose

toLog   = (data) -> log.writeTo "logs/status.log", data

module.exports = (req, res) ->
	statusesTable = config.database.statuses_table
	db = new sqlite3.Database(__dirname + "/../../config/status.db")

	db.serialize( ->
		today = do date.toDay

		db.get(
			"SELECT rowid AS id, status, date FROM #{statusesTable} WHERE date = $today"
			$today: today
			(error, row) ->
				if error then toLog "SQLite Error: #{today} -> #{error}"

				if row && row.status
					str = encodeURIComponent row.status
					url = "https://api.vk.com/method/status.set"
					url += "?group_id=" + config.common.group_id
					url	+= "&text=" + str
					url	+= "&access_token=" + config.common.vk_token

					request(
						url
						(err, head, body) ->
							if err
								toLog "Request error: #{today} -> #{err}"
							else
								toLog "Request body: #{today} -> #{body}"
					)
		)
	)

	do db.close
	do res.end

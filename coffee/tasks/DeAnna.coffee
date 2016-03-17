#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
async = require "async"
sqlite3 = do require("sqlite3").verbose
db = new sqlite3.Database("#{__dirname}/../config/DeAnna.db")

module.exports = (req, res) ->
	#time = (new Date()).getTime / 1000
	request(
		"https://api.instagram.com/v1/users/#{config.common.DeAnna_inst}/media/recent/?access_token=#{config.common.inst_token}&count=3" #&min_timestamp=#{time}
		(error, head, body) ->
			json   = JSON.parse body
			data   = json.data
			images = []

			for item in data
				images.push item.images.standard_resolution.url

			res.send "#{JSON.stringify images}"
	)

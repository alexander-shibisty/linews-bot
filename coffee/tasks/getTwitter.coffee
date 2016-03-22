#work in progress
request = require "request"
config  = require "config"
log     = require "../helpers/logs"
async       = require "async"
Twitter = require 'twitter'

toLog   = (data) -> log.writeTo "logs/twitter.log", data

module.exports = (req, res) ->

	async.waterfall(
		[
			(callback) ->
				client = new Twitter
					consumer_key: config.twitter.consumer_key
					consumer_secret: config.twitter.consumer_secret
					access_token_key: config.twitter.access_token_key
					access_token_secret: config.twitter.access_token_secret

				params =
					screen_name: 'TitanfallEARU'

				client.get(
					'statuses/user_timeline'
					params
					(error, tweets, response) ->
						if error then return callback "Ошибка в twitter api : #{error}", []

						callback null, tweets
				)
		]
		(error, result) ->
			if error
				return callback "Error: #{error}", []
			unless result.length
				return callback "Нет данных", []

			res.send result
	)

	#do res.end

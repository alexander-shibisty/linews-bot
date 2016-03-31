request = require 'request'

setStatus    = require '../tasks/setStatus'
getToken     = require '../tasks/getToken'
getYoutube   = require '../tasks/getYoutube'
getStaemNews = require '../tasks/getStaemNews'
getInstagram = require '../tasks/getInstagram'
getTwitter   = require '../tasks/getTwitter'
getPosts     = require '../tasks/getPosts'
sendPosts    = require '../tasks/sendPosts'
DeAnna       = require '../tasks/DeAnna'
killCaptcha  = require '../tasks/killCaptcha'

describe(
	"Routes tests"
	->
		it("should respond true", ->

			routes_check = on

			routes = [
				setStatus
				getToken
				getYoutube
				getStaemNews
				getInstagram
				getTwitter
				getPosts
				sendPosts
				DeAnna
				killCaptcha
			]

			for route in routes
				unless typeof route == 'function' then routes_check = off

			expect(routes_check).toEqual on
		)
)

express = require 'express'
app     = do express
config  = require 'config'

#include tasks
setStatus    = require './tasks/setStatus'
getToken     = require './tasks/getToken'
getYoutube   = require './tasks/getYoutube'
getStaemNews = require './tasks/getStaemNews'
getInstagram = require './tasks/getInstagram'
getTwitter   = require './tasks/getTwitter'
getPosts     = require './tasks/getPosts'
sendPosts    = require './tasks/sendPosts'
DeAnna       = require './tasks/DeAnna'
killCaptcha       = require './tasks/killCaptcha'

#init routes
app.get '/',             (req, res) -> getToken     req, res
app.get '/setstatus',    (req, res) -> setStatus    req, res
app.get '/getyoutube',   (req, res) -> getYoutube   req, res
app.get '/getsteamnews', (req, res) -> getStaemNews req, res
app.get '/getinstagram', (req, res) -> getInstagram req, res
app.get '/gettwitter',   (req, res) -> getTwitter   req, res
app.get '/getposts',     (req, res) -> getPosts     req, res
app.get '/sendposts',    (req, res) -> sendPosts    req, res
app.get '/deanna',       (req, res) -> DeAnna       req, res
app.get '/killcaptcha',  (req, res) -> killCaptcha  req, res

#last route
app.get '*', (req, res) -> res.status(404).send 'error 404'

app.listen(
	config.backend.port
	->
		console.log "Server is listening on port #{config.backend.port}"
)

express = require 'express'
app = do express
config = require 'config'

#include tasks
getToken = require './tasks/getToken'
setStatus = require './tasks/setStatus'
getYoutube = require './tasks/getYoutube'
#getSteamAction = require './tasks/getSteamAction'
getStaemNews = require './tasks/getStaemNews'
getInstagram = require './tasks/getInstagram'
getTwitter = require './tasks/getTwitter'
DeAnna = require './tasks/DeAnna'

#init routes
app.get '/', (req, res) -> getToken(req, res)
app.get '/setstatus', (req, res) -> setStatus(req, res)
app.get '/getyoutube', (req, res) -> getYoutube(req, res)
#app.get '/getsteamaction', (req, res) -> getSteamAction(req, res)
app.get '/getsteamnews', (req, res) -> getStaemNews(req, res)
app.get '/getinstargram', (req, res) -> getInstagram(req, res)
app.get '/gettwitter', (req, res) -> getTwitter(req, res)
app.get '/deanna', (req, res) -> DeAnna(req, res)

#last route
app.get '*', (req, res) -> res.status(404).send 'error 404'

app.listen(
	config.backend.port
	->
		console.log "Server is listening on port #{config.backend.port}"
)

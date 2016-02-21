express = require 'express'
app = do express
config = require 'config'

#include tasks
getToken = require './tasks/getToken'
setStatus = require './tasks/setStatus'
getYoutube = require './tasks/getYoutube'
getSteamAction = require './tasks/getSteamAction'

#init routes
app.get '/', (req, res) -> getToken(req, res)
app.get '/setstatus', (req, res) -> setStatus(req, res)
app.get '/getyoutube', (req, res) -> getYoutube(req, res)
app.get '/getsteamaction', (req, res) -> getSteamAction(req, res)

#last route
app.get '*', (req, res) -> res.status(404).send 'error 404'

app.listen(
	config.backend.port
	->
		console.log "Server is listening on port #{config.backend.port}"
)

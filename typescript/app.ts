let express = require('express');
let app     = express();
let config  = require('config');

//include tasks
let setStatus    = require('./tasks/setStatus');
let getToken     = require('./tasks/getToken');
let getYoutube   = require('./tasks/getYoutube');
let getStaemNews = require('./tasks/getStaemNews');
let getInstagram = require('./tasks/getInstagram');
let getTwitter   = require('./tasks/getTwitter');
let getPosts     = require('./tasks/getPosts');
let sendPosts    = require('./tasks/sendPosts');
let getCosplays  = require('./tasks/getCosplays');

//init routes
app.get('/', (req, res) => {
	return getToken(req, res);
});

app.get('/setstatus', (req, res) => {
	return setStatus(req, res);
});

app.get('/getyoutube', (req, res) => {
	return getYoutube(req, res);
});

app.get('/getsteamnews', (req, res) => {
	return getStaemNews(req, res);
});

app.get('/getinstagram', (req, res) => {
	return getInstagram(req, res);
});

app.get('/gettwitter', (req, res) => {
	return getTwitter(req, res);
});

app.get('/getposts', (req, res) => {
	return getPosts(req, res);
});

app.get('/sendposts', (req, res) => {
	return sendPosts(req, res);
});

app.get('/getcosplays', (req, res) => {
	return getCosplays(req, res);
});

//last route
app.get('*', (req, res) => {
	return res.status(404).send('error 404');
});

app.listen(
	config.backend.port,
	() => {
		console.log(`Server is listening on port `+ config.backend.port);
	}
);

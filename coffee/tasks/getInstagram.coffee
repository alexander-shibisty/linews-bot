#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
async = require "async"
db = new sqlite3.Database("#{__dirname}/../config/instagram.db")

module.exports = (req, res) ->

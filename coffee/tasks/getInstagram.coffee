#work in progress
request = require "request"
config = require "config"
log = require "../helpers/logs"
async = require "async"
sqlite3 = do require("sqlite3").verbose
db = new sqlite3.Database("#{__dirname}/../config/instagram.db")

module.exports = (req, res) ->

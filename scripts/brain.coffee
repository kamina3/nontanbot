Url   = require "url"
Redis = require "redis"

module.exports = (robot) ->
  info   = Url.parse process.env.REDISCLOUD_URL, true
  client = Redis.createClient(info.port, info.hostname)
  prefix = info.path?.replace('/', '') or 'nontan'

  robot.brain.setAutoSave false

  getData = ->
    client.get "#{prefix}:storage", (err, reply) ->
      if err
        throw err
      else if reply
        robot.logger.info "Data for #{prefix} brain retrieved from Redis"
        robot.brain.mergeData JSON.parse(reply.toString())
      else
        robot.logger.info "Initializing new data for #{prefix} brain"
        robot.brain.mergeData {}

      robot.brain.setAutoSave true

  if info.auth
    client.auth info.auth.split(":")[1], (err) ->
      if err
        robot.logger.error "Failed to authenticate to Redis"
      else
        robot.logger.info "Successfully authenticated to Redis"
        getData()

  client.on "error", (err) ->
    robot.logger.error err

  client.on "connect", ->
    robot.logger.debug "Successfully connected to Redis"
    getData() if not info.auth

  robot.brain.on 'save', (data = {}) ->
    client.set "#{prefix}:storage", JSON.stringify data

  robot.brain.on 'close', ->
    client.quit()

    
  KEY_SCORE = 'key_score'
  getScores = () ->
  	return robot.brain.get(KEY_SCORE) or {}
	changeScore = (name, diff) ->
		source = getScores()
		score = source[name] or 0
		new_score = score + diff
		source[name] = new_score
		robot.brain.set KEY_SCORE, source
		return new_score
	robot.respond /list/i, (msg) ->
		source = getScores()
		console.log source
		for name, score of source
			msg.send "#{name}: #{score}"
	robot.hear /^(.+)\+\+$/i, (msg) ->
		name = msg.match[1]
		new_score = changeScore(name, 1)
		msg.send "#{name}: #{new_score}"
	robot.hear /^(.+)--$/i, (msg) ->
		name = msg.match[1]
		new_score = changeScore(name, -1)
		msg.send "#{name}: #{new_score}"
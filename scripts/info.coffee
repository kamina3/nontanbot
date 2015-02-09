module.exports = (robot) ->
  robot.respond /info/, (msg) ->
  	m = "User: #{msg.message.user.name} CHN: #{msg.message.user.room} RAW: #{msg.message.rowText} TXT: #{msg.message.text}"
  	msg.send m

module.exports = (robot) ->
  robot.enter (msg) ->
    msg.message.user.name
    msg.send "いらっしゃい #{msg.message.user.name}さん♪"

  robot.leave (msg) ->
    msg.send "@#{msg.message.user.name} お疲れ様やんな♪"
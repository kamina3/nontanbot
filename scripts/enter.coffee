
module.exports = (robot) ->
  robot.enter (msg) ->
    msg.message.user.name
    msg.send "おはよう #{msg.message.user.name}さん♪"

  robot.leave (msg) ->
    msg.send "@#{msg.message.user.name} 今日も一日お疲れ様やんな♪"
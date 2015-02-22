module.exports = (robot) ->

  robot.hear /ドム/, (msg) ->
    msg.send '/kick #{msg.message.user.name}'
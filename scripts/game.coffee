
cronJob = require('cron').CronJob
 
module.exports = (robot) ->
  send = (room, msg) ->
    response = new robot.Response(robot, {user : {id : -1, name : room}, text : "none", done : false}, [])
    response.send msg
 
  # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
  new cronJob('0 0 * * * *', () ->
    currentTime = new Date
    send '#non-tan', "今は#{new Date().currentTime.getHours()}:00やね"
  ).start()
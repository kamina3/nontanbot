
cronJob = require('cron').CronJob
 
makeGame = (robot) ->
  pattern = ["グー", "チョキ", "パー"]
  idx = Math.floor(Math.random() * pattern.length)
  hand = pattern[idx]
  txt = "後出しじゃんけんだよ！最初はグー！じゃん！けん！ 「#{hand}」！"
  game = {
    "hand": idx,
    "time": new Date(),
    "user": {}
  }
  robot.brain.set "RSPGame", game
  return txt


judgeGame = (msg, robot, hand) ->
  handDic = {
    "グー": 0,
    "チョキ": 1,
    "パー": 2
  }
  idx = handDic[hand]
  game = robot.brain.get "RSPGame"

  if game.user[msg.message.user.name] == true
    msg.reply "あなたはもうやったやん？"
    return

  game.user[msg.message.user.name] = true
  robot.brain.set "RSPGame", game

  judge = game.hand - idx
  message = ""
  pm = 1

  if judge == -2 or judge == 1
    message = "あなたの勝ち♪"
    pm = 1
  else if judge == 0
    message = "引き分けやね"
    pm = 0
  else
    message = "あなたの負けー♪"
    pm = -1

  
  diffMs = new Date().getTime() - game.time.getTime()
  score = getScore(diffMs) * pm
  saveScore(robot, msg.message.user.name, score)
  msg.reply message + "#{score}ポイントやね♪"

saveScore = (robot, user, addScore) ->
  if user == null
    return

  key = "RSPGameScore"
  scoreObj = robot.brain.get key
  scoreObj = if scoreObj == null then {} else scoreObj
  score = if scoreObj[user] != null then scoreObj[user] else 0
  score += addScore
  scoreObj[user] = score
  robot.brain.set key ,scoreObj

getScore = (mSecond) ->
  score = Math.floor(30 - (mSecond / (1000 * 60)))+1
  return Math.max(score, 1)
  
showScore = (msg, robot) ->
  key = "RSPGameScore"
  scoreObj = robot.brain.get key
  if scoreObj == null
    return
  txt = "今の結果はこんな感じやね♪\n"
  for k, v of scoreObj
    txt += "#{k}: #{v}点\n"
  msg.send txt


module.exports = (robot) ->
  # robot.hear /ゲーム/, (msg) ->
  #   msg.send makeGame(robot)

  robot.hear /^(グー|チョキ|パー)$/, (msg)->
    hand = msg.match[1].trim()
    judgeGame(msg, robot, hand)

  robot.hear /^結果$/, (msg)->
    showScore(msg, robot)

  send = (room, msg) ->
    response = new robot.Response(
      robot,
      {
        user : {id : -1,name : room},
        text : "none",
        done : false
      },
      []
    )
    response.send msg
 
  new cronJob('0 */5 * * * *', () ->
    currentTime = new Date
    send '#non-tan', "今は#{currentTime.getHours()}:00やね\n"+makeGame(robot)
  ).start()




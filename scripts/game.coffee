
cronJob = require('cron').CronJob
 
makeGame = (msg, robot) ->
  pattern = ["グー", "チョキ", "パー"]
  idx = Math.floor(Math.random() * pattern.length)
  hand = pattern[idx]
  txt = "後出しじゃんけんだよ！最初はグー！じゃん！けん！ 「#{hand}」！"
  game = {
    "hand": idx,
    "time": new Date()
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
  judge = game.hand - idx
  message = ""
  if judge == -2 or judge = 1
    message = "あなたの勝ち♪"
  else if judge == 0
    message = "引き分けやね"
  else
    message = "あなたの負けー♪"

  
  diffMs = new Date().getTime() - game.time.getTime()
  score = getScore(diffMs)
  saveScore(robot, msg.message.user.name, score)
  msg.reply message

saveScore = (robot, user, addScore) ->
  if user == null
    console.log "user nil"
    return

  key = "RSPGameScore"
  scoreObj = robot.brain.get key
  scoreObj = if scoreObj == null then {} else scoreObj
  score = if user in scoreObj then scoreObj[user] else 0
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
  robot.hear /ゲーム/, (msg) ->
    msg.send makeGame(msg, robot)

  robot.hear /^(グー|チョキ|パー)$/, (msg)->
    hand = msg.match[1].trim()
    judgeGame(msg, robot, hand)

  robot.hear /^結果$/, (msg)->
    showScore(msg, robot)
  send = (room, msg) ->
    response = new robot.Response(robot, {user : {id : -1, name : room}, text : "none", done : false}, [])
    response.send msg
 
  new cronJob('0 */10 * * * *', () ->
    currentTime = new Date
    send '#non-tan', "今は#{currentTime.getHours()}:00やね\n"+makeGame()
  ).start()




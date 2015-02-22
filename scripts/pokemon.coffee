request = require('request');
cronJob = require('cron').CronJob


newGame = (robot) ->
  key = "PokemonBattle"
  game = robot.brain.get key
  # if existEnemy(robot)
  #   return
  game = {
    "enemy": "",
    "hp": 500,
    "maxhp": 500,
    "atk": 10,
    "lastAttacker": "",
    "usersPokemon": {},
    "userChangeTimes": {},
    "lastAttackDate":new Date().getTime()
  }

  number = Math.floor(Math.random() * 450)
  request.get("http://pokeapi.co/api/v1/pokemon/#{number}", (error, response, body) ->
    if error or response.statusCode != 200
      return
    data = JSON.parse(body)

    game.enemy = data.name
    game.maxhp = data.hp * 5
    game.atk = data.attack
    game.hp = game.maxhp
    robot.brain.set key, game
    text = ">野生の「#{game.enemy}（hp:#{game.hp}/#{game.maxhp}）(atk:#{game.atk})」が出てきたよ！"
    q = "#{game.enemy}+pokemon"
    request.get("http://ajax.googleapis.com/ajax/services/search/images?q=#{q}&v=1.0" ,(error, response, body) ->
      img_url = JSON.parse(body).responseData.results[0].unescapedUrl
      robot.messageRoom 'non-tan', text + '\n' + img_url
    )
  )

newPokemon = (msg, robot) ->
  
  number = Math.floor(Math.random() * 150)
  request.get("http://pokeapi.co/api/v1/pokemon/#{number}", (error, response, body) ->
    if error or response.statusCode != 200
      return
    data = JSON.parse(body)
    key = "PokemonBattle"
    game = robot.brain.get key
    game.usersPokemon[msg.message.user.name] = {
      "name": data.name,
      "atk": data.attack
    }
    count = game.userChangeTimes[msg.message.user.name]
    if !count?
      count = 0
    count += 1
    game.userChangeTimes[msg.message.user.name] = count
    robot.brain.set key, game
    msg.send "ポケモン交代！「#{data.name}（ATK: #{data.attack}）」"
    showPokemonImage(msg, data.name)
  )
showPokemonImage = (msg, pokemon) ->
  q = "#{pokemon}+pokemon"
  # imageMe msg, q, (url) ->
  #   msg.send url
  request.get("http://ajax.googleapis.com/ajax/services/search/images?q=#{q}&v=1.0" ,(error, response, body) ->
    img_url = JSON.parse(body).responseData.results[0].unescapedUrl
    msg.send img_url
  )

checkChangeTime = (msg, robot) ->
  key = "PokemonBattle"
  if !existEnemy(robot)
    return false
  game = robot.brain.get key
  if !game.userChangeTimes[msg.message.user.name]?
    return true

  if game.userChangeTimes[msg.message.user.name] < 3
    return true
  console.log game
  console.log game.usersPokemon[msg.message.user.name]
  return false

existEnemy = (robot) ->
  key = "PokemonBattle"
  game = robot.brain.get key
  if !game? or game.hp == 0
    return false
  else
    return true

attackPokemon = (msg, robot) ->
  if !existEnemy(robot)
    msg.send "敵おらへんよ？"
    return
  key = "PokemonBattle"
  game = robot.brain.get key
  console.log(game)
  if !game.usersPokemon[msg.message.user.name]?
    msg.send "ポケモンいないのにどうやって戦うん？「ポケモンヘルプ」コマンド見てや〜"
    return

  lastDateTime = parseInt(game.lastAttackDate)
  if isNaN(lastDateTime)
    lastDateTime = 0

  if (new Date().getTime() - lastDateTime) > 1000 * 60 * 60
    console.log("timelimit ok")
    game.lastAttacker = "nobody"

  if game.lastAttacker == msg.message.user.name
    msg.send "二度連続攻撃はできひんのやで？"
    return

  pokemon = game.usersPokemon[msg.message.user.name]
  damage = Math.floor(pokemon.atk * (80 + Math.random() * 30) / 100)
  damage = Math.min(damage, game.hp)
  game.hp -= damage
  mes = ">#{pokemon.name}の攻撃！#{game.enemy}に#{damage}ダメージ！\n >残りHP#{game.hp}/#{game.maxhp}\n"
  if game.lastAttacker == ""
    mes += ">最初の攻撃！ボーナスポイント！\n"
    damage += 30

  game.lastAttacker = msg.message.user.name
  game.lastAttackDate = new Date().getTime()
  if game.hp == 0
    mes += ">#{game.enemy}は倒れた！ボーナスポイント！\n"
    damage += 30

  if !game.atk?
    game.atk = Math.floor(100 * Math.random())
    robot.brain.set key, game

  if game.hp > 0
    attack_rate = Math.floor(100 - Math.random() * game.atk)
    if attack_rate > 70
      enemy_atk = Math.floor(game.atk * (80 + Math.random() * 30) / 100)
      mes += ">#{game.enemy}の反撃！#{enemy_atk}ダメージ！\n"
      damage -= enemy_atk
  robot.brain.set key, game
  saveScore(msg, robot, damage)

  # セーブした後に結果出すためのチェック
  if game.hp == 0 
    mes += showScore(robot)
  msg.send mes

saveScore = (msg, robot, addScore) ->
  key = "PokemonBattleScore"
  scoreObj = robot.brain.get key
  if !scoreObj?
    scoreObj = {}
  if !scoreObj[msg.message.user.name]?
    scoreObj[msg.message.user.name] = 0
  scoreObj[msg.message.user.name] += addScore
  if scoreObj[msg.message.user.name] < 0
    scoreObj[msg.message.user.name] = 0
  robot.brain.set key, scoreObj

showScore = (robot) ->
  key = "PokemonBattleScore"
  scoreObj = robot.brain.get key
  if !scoreObj?
    scoreObj = {}
  txt = ""
  for k, v of scoreObj
    txt += "#{k}: #{v}pt\n"
  return txt

resetScore = (msg, robot) ->
  key = "PokemonBattleScore"
  scoreObj = robot.brain.get key
  if !scoreObj?
    scoreObj = {}
  if !scoreObj[msg.message.user.name]?
    scoreObj[msg.message.user.name] = 0
  scoreObj[msg.message.user.name] =0
  robot.brain.set key, scoreObj

module.exports = (robot) ->
  new cronJob('0 0 */8 * * *', () ->
    # if !existEnemy(robot)
    newGame(robot)
  ).start()

  robot.respond /score reset/i, (msg) ->
    resetScore(msg, robot)

  # robot.hear /^はじめ/, (msg) ->
  #   newGame(robot)

  robot.hear /^いけ/i, (msg) ->
    if checkChangeTime(msg, robot)
      newPokemon(msg, robot)
    else
      msg.send "もう変えられないよ？"

  robot.hear /^もどれ/i, (msg) ->
    if checkChangeTime(msg, robot)
      newPokemon(msg, robot)
    else
      msg.send "もう変えられないよ？"

  robot.hear /^たたか[う|え]/i, (msg) ->
    attackPokemon(msg, robot)

  robot.hear /^戦績$/i, (msg) ->
    msg.send showScore(robot)

  robot.hear /ポケモンヘルプ$/i, (msg) ->
    msg.send "help: 参加 「いけ」/ 攻撃「たたかう」ポケモン変更「もどれ」現在の結果「戦績」"

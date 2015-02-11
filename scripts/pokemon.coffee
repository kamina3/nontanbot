request = require('request');
cronJob = require('cron').CronJob


newGame = (robot) ->
  key = "PokemonBattle"
  game = robot.brain.get key
  if existEnemy(robot)
    return
  game = {
    "enemy": "",
    "hp": 500,
    "lastAttacker": "",
    "usersPokemon": {},
    "userChangeTimes": {}
  }
  game.enemy = "にせかみなさん"
  robot.brain.set key, game
  robot.messageRoom 'pokemon', "野生の「#{game.enemy}」が出てきたよ！"

newPokemon = (msg, robot) ->
  
  number = Math.floor(Math.random() * 150)
  request.get("http://pokeapi.co/api/v1/pokemon/#{number}", (error, response, body) ->
    if error or response.statusCode != 200
      return
    data = JSON.parse(body)
    # msg.send data.name
    key = "PokemonBattle"
    game = robot.brain.get key
    game.usersPokemon[msg.message.user.name] = {
      "name": data.name,
      "atk": data.attack
    }
    count = game.userChangeTimes[msg.message.user.name]
    if count == null or isNaN(count)
      count = 0
    count += 1
    game.userChangeTimes[msg.message.user.name] = count
    robot.brain.set key, game
    msg.send "ポケモン交代！「#{data.name}」"
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
  if game == null or game.hp == 0
    console.log "敵がいないっぽいね？"
    return false
  else
    return true

attackPokemon = (msg, robot) ->
  if !existEnemy(robot)
    return
  key = "PokemonBattle"
  game = robot.brain.get key
  if !game.usersPokemon[msg.message.user.name]?
    msg.send "ポケモンいないのにどうやって戦うん？「join」コマンドで参加やで〜"
    return

  if game.lastAttacker == msg.message.user.name
    msg.send "二度連続攻撃はできひんのやで？"
    return

  pokemon = game.usersPokemon[msg.message.user.name]
  damage = Math.floor(pokemon.atk * (80 + Math.random() * 30) / 100)
  damage = Math.min(damage, game.hp)
  game.hp -= damage
  mes = "#{game.enemy}に#{damage}ダメージ！\n"
  if game.lastAttacker == ""
    mes += "最初の攻撃！ボーナスポイント！\n"
    damage += 30
  game.lastAttacker = msg.message.user.name
  if game.hp == 0
    mes += "#{game.enemy}は倒れた！ボーナスポイント！\n"
    damage += 30
  robot.brain.set key, game
  saveScore(msg, robot, damage)

  if game.hp == 0 # セーブした後に結果出すためのチェック
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

module.exports = (robot) ->
  new cronJob('0 0 6 * * *', () ->
    if !existEnemy(robot)
      newGame(robot)
  ).start()

  robot.hear /^join/, (msg) ->
    if checkChangeTime(msg, robot)
      newPokemon(msg, robot)
    else
      msg.send "もう変えられないよ？"

  robot.hear /^change/, (msg) ->
    if checkChangeTime(msg, robot)
      newPokemon(msg, robot)
    else
      msg.send "もう変えられないよ？"

  robot.hear /^attack/, (msg) ->
    attackPokemon(msg, robot)

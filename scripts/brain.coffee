
isType = (type, obj) ->
  clas = Object.prototype.toString.call(obj).slice(8, -1)
  return obj? and clas == type

module.exports = (robot) ->

  robot.hear /^記録して\s+(.*)\s+(.*)$/i, (msg) ->
    key = msg.match[1].trim()
    value = msg.match[2].trim()
    robot.brain.set key, value
    msg.reply "「#{key}」は「 #{value} 」やね"

  robot.hear /^のんたんおぼえて\s+(.*)\s+(.*)$/i, (msg) ->
    key = msg.match[1].trim()
    value = msg.match[2].trim()
    obj = robot.brain.get key
    if !obj? or isType('String', obj)
      obj = {}
    obj[msg.message.user.name] = value
    robot.brain.set key, obj
    msg.reply "「#{key}」は「 #{value} 」やね"

  robot.hear /^のんたんおしえて\s+(.*)$/i, (msg) ->
    key = msg.match[1].trim()
    value = robot.brain.get(key) or null
    if isType('String', value)
      msg.reply "「#{key}」はこれやろ？\n#{value}"
    else if value?
      text = ""
      mine = ""
      for k, v of value
        if k == msg.message.user.name and k == key
          mine = "ちなみにあなた自身は「#{v}」やって言ってたで？覚えてる？"
        else if k == msg.message.user.name
          mine = "ちなみにあなた自身は「#{key}」のこと、「#{v}」やって言ってたやんな？"
        else if k == key
          text += "「#{k}」自身は「#{v}」、"
        else
          text += "「#{k}」は「#{v}」、"
      if text.length > 0
        msg.reply "ああ、えっと「#{key}」のことやね、\n#{text}って言ってたやんな\n#{mine}"
    else
      msg.reply "それは知らんみたい... ごめんね。"

  robot.hear /^(.*)\s+とは$/, (msg) ->
    key = msg.match[1].trim()
    value = robot.brain.get(key) or null
    if value?
      msg.reply "あ、それウチ知ってるよ。「#{key}」は「#{value}」やんな？"
    else
      msg.reply "うーん、聞いたことないなー"
  
module.exports = (robot) ->

  robot.hear /^のんたんおぼえて\s+(.*)\s+(.*)$/i, (msg) ->
    key = msg.match[1].trim()
    value = msg.match[2].trim()
    robot.brain.set key, value
    msg.reply "「#{key}」は「#{value}」やね"

  robot.hear /^のんたんおしえて\s+(.*)$/i, (msg) ->
    key = msg.match[1].trim()
    value = robot.brain.get(key) or null
    if value != null
      msg.reply "これやろ？\n#{value}"
    else
      msg.reply "それは知らんみたい... ごめんね。"
  
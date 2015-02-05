// Generated by CoffeeScript 1.9.0
var SOURCES, getGif, tumblr;

tumblr = require("tumblrbot");

SOURCES = {
  "kamina3.tumblr.com": "kamina3.tumblr.com"
};

getGif = function(blog, msg) {
  return tumblr.photos(blog).random(function(post) {
    return msg.send(post.photos[0].original_size.url);
  });
};

module.exports = function(robot) {
  robot.hear(/のんたん$/, function(msg) {
    return msg.send(msg.random(["ウチのスピリチュアルパワーをあなたに注入♪", "ウチのこと呼んだ？", "手伝いついでに運勢も占ったげようか？", "おつかれー！しっかりやすむんよ？", "ウチの趣味は占いなんよ。占ってあげよか？"]));
  });
  return robot.respond(/tumblr/i, function(msg) {
    var blog;
    blog = msg.random(Object.keys(SOURCES));
    return getGif(blog, msg);
  });
};
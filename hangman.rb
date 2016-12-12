# dafeng@strikingly.com
# 200, post, capital letters

require 'net/http'
require 'json'

def start_game(playerId = "dafeng@strikingly.com")
  uri = URI('https://strikingly-hangman.herokuapp.com/game/on')
  req = Net::HTTP::Post.new(uri)
  req.body = {playerId: playerId, action: "startGame"}.to_json
  req.content_type = 'application/json'

  raw_res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request(req)
  end

  case raw_res
  when Net::HTTPSuccess
    response = JSON.parse(raw_res.body)
    sessionId = response["sessionId"]
  else
    "Please check playerId."
  end
end

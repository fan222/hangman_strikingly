# dafeng@strikingly.com
# 200, post, capital letters

require 'net/http'
require 'json'
require 'byebug'

class Hangman
  MAX_GUESSES = 10
  MAX_WORDS_NUM = 80
  attr_reader :board

  def initialize(playerId = "dafeng@strikingly.com")
    @guesser = Guesser.new(playerId)
  end

  def play
    @guesser.start_game
    MAX_WORDS_NUM.times do |word_idx|
      setup
      MAX_GUESSES.times do |num_guesses|
        p [word_idx, num_guesses]
        take_turn
        next if won?
      end
    end

    puts @guesser.submit_result
  end

  def setup
    next_word_callback = @guesser.next_word
    if next_word_callback[:success]
      secret_length = next_word_callback[:word].length
      @guesser.register_secret_length(secret_length)
      @board = [nil] * secret_length
    end
  end

  def take_turn
    guess = @guesser.guess(@board)
    unless guess.nil?
      indices = @guesser.make_guess(guess)
      update_board(guess, indices)
      @guesser.handle_response(guess, indices)
    end
  end

  def update_board(guess, indices)
    indices.each { |index| @board[index] = guess }
  end

  def won?
    @board.all?
  end

end

class Guesser

  attr_reader :playerId, :sessionId
  attr_reader :candidate_words

  def initialize(playerId)
    @playerId = playerId
    @dictionary = File.readlines("dictionary.txt").map(&:chomp)
  end

  def register_secret_length(length)
    @candidate_words = @dictionary.select { |word| word.length == length }
  end

  def start_game
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
      @sessionId = response["sessionId"]
      {success: true, sessionId: sessionId}
    else
      {success: false, message: "Please check playerId."}
    end
  end

  def next_word
    uri = URI('https://strikingly-hangman.herokuapp.com/game/on')
    req = Net::HTTP::Post.new(uri)
    req.body = {sessionId: sessionId, action: "nextWord"}.to_json

    raw_res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end

    case raw_res
    when Net::HTTPSuccess
      response = JSON.parse(raw_res.body)
      word = response["data"]["word"]
      {success: true, word: word}
    else
      {success: false, message: "Fail to get new word."}
    end
  end

  def make_guess(letter)
    uri = URI('https://strikingly-hangman.herokuapp.com/game/on')
    req = Net::HTTP::Post.new(uri)
    req.body = {sessionId: sessionId, action: "guessWord", guess: letter.capitalize}.to_json

    raw_res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end

    case raw_res
    when Net::HTTPSuccess
      response = JSON.parse(raw_res.body)
      response["data"]["word"]
      check_guess(response["data"]["word"], letter)
    else
      {success: false, message: "Fail to make a guess."}
    end
  end

  def check_guess(secret_word, guess)
    response = []
    secret_word.split("").each_with_index do |letter, index|
      response << index if letter == guess.capitalize
    end
    response
  end

  def submit_result
    uri = URI('https://strikingly-hangman.herokuapp.com/game/on')
    req = Net::HTTP::Post.new(uri)
    req.body = {sessionId: sessionId, action: "submitResult"}.to_json

    raw_res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end

    case raw_res
    when Net::HTTPSuccess
      response = JSON.parse(raw_res.body)
      data = response["data"]
      { success: true, score: data["score"], playerId: data["playerId"],
        totalWordCount: data["totalWordCount"],
        correctWordCount: data["correctWordCount"],
        totalWrongGuessCount: data["totalWrongGuessCount"],}
    else
      {success: false, message: "Fail to submit result."}
    end
  end

  def guess(board)
    freq_table = freq_table(board)

    most_frequent_letters = freq_table.sort_by { |letter, count| count }
    letter, _ = most_frequent_letters.last
    letter
  end

  def handle_response(guess, response_indices)
    @candidate_words.reject! do |word|
      should_delete = false
      word.split("").each_with_index do |letter, index|
        if (letter == guess) && (!response_indices.include?(index))
          should_delete = true
          break
        elsif (letter != guess) && (response_indices.include?(index))
          should_delete = true
          break
        end
      end
      should_delete
    end
  end

  private
  def freq_table(board)
    # this makes 0 the default value; see the RubyDoc.
    freq_table = Hash.new(0)

    @candidate_words.each do |word|
      board.each_with_index do |letter, index|
        # only count letters at missing positions
        freq_table[word[index]] += 1 if letter.nil?
      end
    end
    freq_table
  end
end


if __FILE__ == $PROGRAM_NAME
  game = Hangman.new()
  game.play
end

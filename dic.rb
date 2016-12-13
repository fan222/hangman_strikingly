dictionary = File.readlines("dictionary.txt").map(&:chomp)
board = [nil, "e", nil, "t", nil]
matched_words = @dictionary.select do |word|
  board.each_with_index.all? do |chr, idx|
    if chr.nil?
      true
    else
      if word[idx] == chr && word.length.between?(board.length-2, board.length+2)
        true
      else
        false
      end
    end
  end
end
freq_table = Hash.new(0)
matched_words.each do |word|
  board.each_with_index do |letter, index|
    freq_table[word[index]] += 1 if letter.nil?
  end
end
freq_table
most_frequent_letters = freq_table.sort_by { |letter, count| count }
letter, _ = most_frequent_letters.last
letter

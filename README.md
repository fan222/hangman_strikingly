# hangman_strikingly

## how to play

**cd** to **hangman_strikingly** dir, then type
```ruby
  ruby hangman.rb
```
The program will run automatically. After it finish, the result will show in the console like

```ruby
{:success=>true, :score=>847, :playerId=>"example@something.com", :totalWordCount=>80, :correctWordCount=>52, :totalWrongGuessCount=>193}
```

## Game Solver logic

Each time a new secret word is given, the program filters the dictionary, finding all words with right length.
```ruby
  @candidate_words = @dictionary.select { |word| word.length == length }
```

Then the frequency of all letters in **@candidate_words** is calculated. The most common letter is returned.
```ruby
  freq_table = freq_table(board)
  most_frequent_letters = freq_table.sort_by { |letter, count| count }
  letter, _ = most_frequent_letters.last
  letter
```

After a right letter is found, **@candidate_words** are updated. Words with right letter at wrong position or at right position with right letter are deleted.
```ruby
  if (letter == guess) && (!response_indices.include?(index))
    should_delete = true
    break
  elsif (letter != guess) && (response_indices.include?(index))
    should_delete = true
    break
  end
```

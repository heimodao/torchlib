--[[ Implementation of a vocabulary class ]]
local Vocab = torch.class("Vocab")

--[[ Constructor.
  Parameters:
  - `unk`: the symbol for the unknown token.
]]
function Vocab:__init(unk)
  self.unk = unk or 'UNK'
  self.index2word = {}
  self.word2index = {}
  self.counter = {}
  if self.unk ~= nil then
    table.insert(self.index2word, self.unk)
    self.word2index[self.unk] = self:size()
    self.counter[self.unk] = 0;
  end
end

function Vocab:toString()
  return "Vocab("..self:size()..' words, unk='..self.unk..")"
end
torch.getmetatable('Vocab').__tostring__ = Vocab.toString

--[[ Returns whether `word` is in the vocabulary. ]]
function Vocab:contains(word)
  return self.word2index[word] ~= nil
end

--[[ Returns the count for `word` seen during training. ]]
function Vocab:count(word)
  assert(self:contains(word), 'Error: attempted to get count of word ' .. word .. ' which is not in the vocabulary')
  return self.counter[word]
end

--[[ Returns how many distinct tokens are in the vocabulary. ]]
function Vocab:size()
  return #self.index2word
end

--[[ Adds `word` `count` time to the vocabulary. ]]
function Vocab:add(word, count)
  count = count or 1 
  if self:contains(word) then
    self.counter[word] = self:count(word) + count
  else
    self.counter[word] = count
    table.insert(self.index2word, word)
    self.word2index[word] = self:size()
  end
  return self.word2index[word]
end

--[[ Returns the index of `word`. If the word is not found, then one of the following occurs:
  - if `add` is `true`, then `word` is added to the vocabulary with count 1 and the new index returned
  - otherwise, the index of the unknown token is returned
]]
function Vocab:indexOf(word, add)
  add = add or false
  if add then
    return self:add(word, 1)
  end
  if not self:contains(word) then
    return self:indexOf(self.unk)
  end
  return self.word2index[word]
end

--[[ Returns the word at index `index`. If `index` is out of bounds then an error will be raised. ]]
function Vocab:wordAt(index)
  assert(index <= self:size(), 'Error: attempted to get word at index ' .. index .. ' which exceeds the vocab size')
  return self.index2word[index]
end

--[[ `indexOf` on a table of words. Returns a table of corresponding indices. ]]
function Vocab:indicesOf(words, add)
  add = add or false
  indices = {}
  for i, word in ipairs(words) do
    table.insert(indices, self:indexOf(word, add))
  end
  return indices
end

--[[ `indexOf` on a table of words. Returns a tensor of corresponding indices. ]]
function Vocab:tensorIndicesOf(words, add)
  add = add or false
  indices = torch.Tensor(#words)
  for i, word in ipairs(words) do
    indices[i] = self:indexOf(word, add)
  end
  return indices
end

--[[ `wordAt` on a table of indices. Returns a table of corresponding words. ]]
function Vocab:wordsAt(indices)
  words = {}
  for i, index in ipairs(indices) do
    table.insert(words, self:wordAt(index))
  end
  return words
end

--[[ `wordAt` on a tensor of indices. Returns a table of corresponding words. ]]
function Vocab:tensorWordsAt(indices)
  words = {}
  for i = 1, indices:size(1) do
    table.insert(words, self:wordAt(indices[i]))
  end
  return words
end

--[[ Returns a new vocabulary with words occurring less than `cutoff` times removed. ]]
function Vocab:copyAndPruneRares(cutoff)
  v = self.new(self.unk)
  for i, word in ipairs(self.index2word) do
    count = self:count(word)
    if (count >= cutoff or word == self.unk) then
      v:add(word, count)
    end
  end
  return v
end

--[[ Returns the embedding matrix corresponding to this vocabulary. The `folder` must contain:
  - `words.lst`: each line contains a word in the vocabulary
  - `embeddings.txt`: each line contains a vector corresponding to the word on the same line
]]
function Vocab:pretrained(folder)
  local wordlist = paths.concat(folder, 'words.lst')
  local embeddings = paths.concat(folder, 'embeddings.txt')
  assert(paths.filep(wordlist), 'Error: wordlists does not exist at ' .. wordlist)
  assert(paths.filep(embeddings), 'Error: wordlists does not exist at ' .. embeddings)
  -- add each word in the wordlist
  local words = {}
  for line in io.lines(wordlist) do
    -- remove the last character, which is newline
    local word = string.sub(line, 1, -1)
    table.insert(words, word)
  end
  -- load vectors
  local emb = torch.Tensor(self:size(), 50):uniform(-0.1, 0.1)
  local i = 1
  for line in io.lines(embeddings) do
    -- remove the last character, which is newline
    local numbers = string.split(line, '%s+')
    local word = words[i]
    if self:contains(word) then
      local ind = self:indexOf(word)
      assert(#numbers == 50, 'Error: cannot parse embedding ' .. tostring(line))
      emb[ind] = torch.Tensor(numbers)
    end
    i = i + 1
  end
  return emb
end

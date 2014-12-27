using TextGrams.Document

export Ngrams, copy

# Public types and functions

typealias Ngrams Dict{ASCIIString,Integer}

function Ngrams(arr::Array{Any,2})
  d = Ngrams()
  for i in 1:size(arr, 1)
    try
      d[convert(ASCIIString, arr[i,1])] = arr[i,2]
    catch e
      println(STDERR, "'$(arr[i,1])' ($(typeof(arr[i,1]))) $(arr[i,2]) ($(typeof(arr[i,2])))")
      rethrow(e)
    end
  end
  return d
end

function Ngrams(file::IOStream)
  arr = readdlm(file, '\t')
  close(file)
  Ngrams(arr)
end

function Ngrams(d::Document, n::Integer = 1)
  ngramizeNgrams(d.content, n)
end

function Ngrams(text::String, n::Integer = 1)
  ngramizeNgrams(text, n)
end

# Private functions

function ngramizeNgrams(text::String, n::Integer)
  d = Ngrams()

  head = next_head = 1
  while head < length(text)
    tail = head
    separators = 0
    while tail < length(text)
      if text[tail] == ' ' || text[tail] == '.'
        separators += 1
        incrementedSubstring(d, text, head, tail-1)
        if separators == 1
          next_head = tail + 1
        end
        if separators == n
          break
        end
      end
      tail += 1
    end
    if tail == length(text)
      incrementedSubstring(d, text, head, tail)
      if separators == 0
        break
      end
    end
    head = next_head
  end

  return d
end

function incrementedSubstring(dict, text, head, tail)
  key = text[head:tail]
  counter = get!(dict, key, 0)
  dict[key] = counter + 1
end

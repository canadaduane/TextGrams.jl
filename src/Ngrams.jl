using TextGrams.Document

export Ngrams, copy

# Public types and functions

typealias Ngrams Dict{ASCIIString,Integer}

function Ngrams(arr::Array{ASCIIString,2})
  d = Ngrams()
  for i in 1:size(arr, 1)
    try
      key = convert(ASCIIString, arr[i,1])
      value = int(arr[i,2])
      d[key] = value
    catch e
      println(STDERR, "'$(arr[i,1])' ($(typeof(arr[i,1]))) $(arr[i,2]) ($(typeof(arr[i,2])))")
      rethrow(e)
    end
  end
  return d
end

function Ngrams(file::IOStream)
  Ngrams(file, (n) -> ())
end

function Ngrams(file::IOStream, callback::Function)
  d = Ngrams()
  for line::ASCIIString in eachline(file)
    tab = search(line, '\t')
    try
      d[line[1:(tab-1)]] = int(line[(tab+1):end-1])
    catch
      d[line[1:(tab-1)]] = int(line[(tab+1):end])
    end
    callback(length(line))
  end
  d
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
      if text[tail] == '\n'
        # End of line means sentence separator
        incrementSubstring(d, text, head, tail-1)
        if separators == 0
          next_head = tail + 1
        end
        break
      elseif text[tail] == ' ' || text[tail] == '.'
        separators += 1
        incrementSubstring(d, text, head, tail-1)
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
      incrementSubstring(d, text, head, tail)
      if separators == 0
        break
      end
    end
    head = next_head
  end

  return d
end

function incrementSubstring(dict, text, head, tail)
  key = text[head:tail]
  counter = get!(dict, key, 0)
  dict[key] = counter + 1
end

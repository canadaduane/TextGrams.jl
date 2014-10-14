function _ngramize_incr(dict, text, head, tail)
  key = text[head:tail]
  counter = get!(dict, key, 0)
  dict[key] = counter + 1
end

function ngramize(text::String, n::Integer)
  if n == 1
    _ngramize_unigrams(text)
  else
    _ngramize_ngrams(text, n)
  end
end

function _ngramize_ngrams(text::String, n::Integer)
  d = Dict{typeof(text), Integer}()

  head = next_head = 1
  while head < length(text)
    tail = head
    separators = 0
    while tail < length(text)
      if text[tail] == ' ' || text[tail] == '.'
        separators += 1
        _ngramize_incr(d, text, head, tail-1)
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
      _ngramize_incr(d, text, head, tail)
      if separators == 0
        break
      end
    end
    head = next_head
  end

  return d
end

function _ngramize_unigrams(text::String)
  # TODO: Optimize this
  _ngramize_ngrams(text, 1)
end

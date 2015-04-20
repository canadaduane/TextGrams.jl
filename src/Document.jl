using MutableStrings
using Base

export Document, copy, wordcount, splitDocument

import Base.copy

type Document
  content::MutableASCIIString
  title::String
  function Document(c::MutableASCIIString, t=None, cleanIt=true)
    if cleanIt
      clean!(c)
    end
    new(c, t == None ? titleFromContent(c) : t)
  end
end

function Document(content::String, title=None, cleanIt=true)
  Document(MutableASCIIString(content), title, cleanIt)
end

function Document(content::String, title=None)
  Document(MutableASCIIString(content), title)
end

function Document(file::IOStream, title=None)
  text = readall(file)
  close(file)
  Document(text, title)
end

function titleFromContent(content)
  short = strip(length(content) > 35 ? content[1:35] : content)
  return replace(short, r"\s+", " ")
end

function copy(d::Document)
  Document(d.content, copy(d.title))
end

function wordcount(d::Document)
  count(c -> c == ' ' || c == '\n', collect(d.content))
end

function splitDocument(d::Document, wordsPer::Integer)
  index = 0
  splitIndex = 1
  prevSplitIndex = 0
  documents = Document[]
  while splitIndex > 0
    splitIndex = searchNth(d.content, ' ', wordsPer, splitIndex + 1)
    if splitIndex > 0
      # middle chunk, split from prev to current index
      push!(documents, Document(d.content[(prevSplitIndex+1):(splitIndex-1)], None, false))
    else
      # last chunk, split to end
      push!(documents, Document(d.content[(prevSplitIndex+1):end], None, false))
      break
    end
    prevSplitIndex = splitIndex
  end
  return documents
end

function searchNth(s::MutableASCIIString, chars, n::Integer, index = 0)
  for i in range(1, n)
    index = search(s, chars, index+1)
    # shortcut if nothing found
    if index == 0
      break
    end
  end
  return index
end
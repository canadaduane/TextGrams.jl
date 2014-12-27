using MutableStrings

export Document, copy

type Document
  content::MutableASCIIString
  title::String
  function Document(c::MutableASCIIString, t = None)
    clean!(c)
    new(c, t == None ? titleFromContent(c) : t)
  end
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
  short = length(content) > 35 ? content[1:35] : content
  return replace(short, r"\s+", " ")
end

function copy(d::Document)
  Document(d.content, copy(d.title))
end

module TextGrams

include("clean.jl")
include("FileUtils.jl")

include("Document.jl")
include("Ngrams.jl")
include("NgramsSets.jl")

export ngramsOfTextFile
function ngramsOfTextFile(filename, title = None, n::Integer = 1)
  Ngrams(Document(open(filename), title), n)
end

end
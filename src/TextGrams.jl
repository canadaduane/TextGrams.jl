module TextGrams

export ngramize
export union_add,  union_sub,  intersect_add,  delete
export union_add!, union_sub!, intersect_add!, delete!
export clean
export clean!
export each_file, file_producer

include("ngrams.jl")
include("ngram_sets.jl")
include("text.jl")
include("file.jl")

end
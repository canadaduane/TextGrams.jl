module TextGrams

export ngramize
export union_add,  intersect_add,  subtract_del
export union_add!, intersect_add!, subtract_del!
export clean
export clean!
export each_file, file_producer

include("ngrams.jl")
include("ngram_sets.jl")
include("text.jl")
include("file.jl")

end
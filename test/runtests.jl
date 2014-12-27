using FactCheck
using TextGrams

include("helpers.jl")

include("TestDocument.jl")
include("TestNgrams.jl")
include("TestNgramsSets.jl")

facts("TextGrams") do
  context("ngramsOfTextFile") do
    ngrams = ngramsOfTextFile(fixture("samples/liahona.txt"))
    @fact ngrams["and"] => 5
    @fact ngrams["curious"] => 1
  end
end
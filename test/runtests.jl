module TextGramTests

using Base.Test
using MutableStrings
using TextGrams

include("helpers.jl")

# Tests
function test_ngram_paragraph()
  @printf("%35s\n", "test_ngram_paragraph")
  ng = ngramize("a word.ok two.ok", 3)
  @assert(length(ng) == 11, "expected 11 keys, got $(ng)")
end

function test_ngram_three_words()
  @printf("%35s\n", "test_ngram_three_words")
  ng = ngramize("test test words", 3)
  @assert(length(ng) == 5, "expected 5 keys, got $(ng)")
  @assert ng == [
    "test" => 2, "words" => 1, "test test" => 1,
    "test words" => 1, "test test words" => 1]
end

function test_ngram_three_words_unigram()
  @printf("%35s\n", "test_ngram_three_words_unigram")
  ng = ngramize("test test words", 1)
  @assert(length(ng) == 2, "expected 3 unigrams, got $(ng)")
  @assert ng == ["test" => 2, "words" => 1]
end

function test_ngram_one_word()
  @printf("%35s\n", "test_ngram_one_word")
  ng = ngramize("test", 3)
  @test length(ng) == 1
  @assert ng == ["test" => 1]
end

function bench_ngramize()
  @printf("%35s\n", "bench_ngramize")
  open(fixture("bom.txt")) do f
    text = readall(f)
    time_and_print("ngramize", 3, ngramize, text, 4)
  end
end

function bench_text_clean()
  @printf("%35s\n", "bench_text_clean")
  open(fixture("bom.txt")) do f
    text = readall(f)
    time_and_print("clean!", 1, clean!, MutableASCIIString(text))
  end
end

function test_ngram_union_add()
  @printf("%35s\n", "test_ngram_union_add")
  d1 = ngramize("test test words", 1)
  d2 = ngramize("test some words", 1)
  union_add!(d1, d2)
  @assert(d1 == ["test" => 3, "words" => 2, "some" => 1], "got $d1")
end

function bench_ngram_union_add()
  @printf("%35s\n", "bench_ngram_union_add")
  d1 = ngramize("test test words", 1)
  d2 = ngramize("test some words", 1)
  union_add!(d1, d2)
  @assert(d1 == ["test" => 3, "words" => 2, "some" => 1], "got $d1")
end

function test_ngram_intersect_add()
  @printf("%35s\n", "test_ngram_intersect_add")
  d1 = ngramize("test test words", 1)
  d2 = ngramize("test some words", 1)
  intersect_add!(d1, d2)
  @assert(d1 == ["test" => 3, "words" => 2], "got $d1")
end

test_ngram_one_word()
test_ngram_three_words()
test_ngram_three_words_unigram()
test_ngram_paragraph()
test_ngram_union_add()
test_ngram_intersect_add()

bench_ngramize()
bench_text_clean()
bench_ngram_union_add()

end
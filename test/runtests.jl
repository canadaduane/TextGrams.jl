using Base.Test
using MutableStrings
@everywhere using TextGrams

function time_and_print(name, rounds, fn, args...)
  time = 0.0
  memory = 0.0
  for i in 1:rounds
    gc()
    _ret, t, m = @timed str = fn(args...)
    time += t
    memory += m
    @printf("%35s%20s%20s\n", "$i-$name", "$(round(t, 5))", "$(m)")
  end
  @printf("%35s%20s%20s\n", "AVG-$name", "$(round(time/rounds, 5))", "$(integer(memory/rounds))")
end

function fixture(file)
  joinpath(dirname(@__FILE__()), file)
end

function with_fixtures(fn::Function, files...)
  file_contents = String[]
  for f in files
    open(fixture(f)) do fh
      push!(file_contents, readall(fh))
    end
  end
  fn(file_contents...)
end

@everywhere const sample_docs = ASCIIString[
    "PALMYRA: PRINTED BY E. B. GRANDIN, FOR THE AUTHOR. 1830."
    "For it came to pass in the commencement of the first year of the reign of Zedekiah, king of Judah"
    "NOW it came to pass , in the one thousand eight hundred and twelfth year of the christian era"
    "to his great astonishment, he beheld upon the ground a round ball, of curious workmanship; and it was of fine brass"
    "But the imaginary evils which the children of men commit are oftentimes graven in brass"
    "Guy gat great honor , and the people gave him a sword of curious workmanship."
  ]

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

function test_ngram_union_add()
  @printf("%35s\n", "test_ngram_union_add")
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

function test_ngram_delete()
  @printf("%35s\n", "test_ngram_subtract_del")
  d1 = ngramize("test some words", 1)
  d2 = ngramize("test test words", 1)
  delete!(d1, d2)
  @assert(d1 == ["some" => 1], "got $d1")
end

function bench_parallel_union_add()
  @printf("%35s\n", "test_parallel_union_add")
  @everywhere docs = [clean(d^500) for d in sample_docs]
  # println("length(docs):", length(docs))
  _, lbt, lbm = @timed lbase = union_add([ngramize(docs[i], 4) for i in 1:length(docs)]...)
  _, pbt, pbm = @timed pbase = @parallel union_add for i in 1:length(docs)
    ngramize(docs[i], 4)
  end
  @printf("%35s%20s%20s\n", "linear-union_add", lbt, lbm)
  @printf("%35s%20s%20s\n", "parallel-union_add", pbt, pbm)
  @assert(lbase == pbase)
end

function bench_ngramize()
  @printf("%35s\n", "bench_ngramize")
  with_fixtures(joinpath("samples", "bom.txt")) do bom
    time_and_print("ngramize", 3, ngramize, bom, 4)
  end
end

function bench_text_clean()
  @printf("%35s\n", "bench_text_clean")
  with_fixtures(joinpath("samples", "bom.txt")) do bom
    time_and_print("clean", 1, clean, MutableASCIIString(bom))
  end
end

function bench_ngram_add(type_name, fn, n=3)
  @printf("%35s\n", "bench_ngram_$(type_name)_add 1-to-$(n)-grams")
  with_fixtures(joinpath("samples", "bom.txt"), joinpath("samples", "tlw.txt")) do bom, tlw
    m_bom = MutableASCIIString(bom)
    m_tlw = MutableASCIIString(tlw)
    clean!(m_bom)
    clean!(m_tlw)
    bom_dict = ngramize(m_bom, n)
    tlw_dict = ngramize(m_tlw, n)
    time_and_print("$(type_name)_add!", 1, fn, bom_dict, tlw_dict)
  end
end

@printf("%35s%20s%20s\n", "TEST NAME", "TIME", "MEMORY")

test_ngram_one_word()
test_ngram_three_words()
test_ngram_three_words_unigram()
test_ngram_paragraph()
test_ngram_union_add()
test_ngram_intersect_add()
test_ngram_delete()

bench_ngramize()
bench_text_clean()
bench_ngram_add("union", union_add!, 3)
bench_ngram_add("union", union_add!, 4)
bench_ngram_add("intersect", intersect_add!, 3)
bench_ngram_add("intersect", intersect_add!, 4)
bench_parallel_union_add()

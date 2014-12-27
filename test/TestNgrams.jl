facts("Ngrams") do
  context("initializes with dict") do
    ngrams = Ngrams({"test" => 1})
    @fact ngrams["test"] => 1
  end

  context("initializes with text") do
    ngrams = Ngrams("good is good", 1)
    @fact ngrams => {"is" => 1, "good" => 2}
  end

  context("counts bigrams") do
    ngrams = Ngrams("good is good", 2)
    @fact ngrams => {"is" => 1, "good" => 2, "good is" => 1, "is good" => 1}
  end

  context("loads from tab-separated text file") do
    ngrams = Ngrams(open(fixture("samples/simple.2grams.txt")))
    @fact ngrams => {"one world" => 1, "to reinvent" => 2}
  end
end
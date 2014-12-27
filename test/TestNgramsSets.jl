facts("NgramsSets") do
  context("unionAdd same keys") do
    ngrams = unionAdd(Ngrams({"test" => 1}), Ngrams({"test" => 2}))
    @fact ngrams["test"] => 3
  end

  context("unionAdd new keys") do
    ngrams = unionAdd(Ngrams({"test" => 1}), Ngrams({"new" => 2}))
    @fact ngrams => {"test" => 1, "new" => 2}
  end

  context("intersectAdd same keys") do
    ngrams = intersectAdd(Ngrams({"test" => 1}), Ngrams({"test" => 2}))
    @fact ngrams["test"] => 3
  end

  context("intersectAdd new keys") do
    ngrams = intersectAdd(Ngrams({"test" => 1}), Ngrams({"new" => 2}))
    @fact ngrams => {"test" => 1}
  end

  context("unionSub same keys") do
    ngrams = unionSub(Ngrams({"test" => 1}), Ngrams({"test" => 2}))
    @fact ngrams["test"] => 0
  end

  context("unionSub new keys") do
    ngrams = unionSub(Ngrams({"test" => 1}), Ngrams({"new" => 2}))
    @fact ngrams => {"test" => 1}
  end

  context("delete keys") do
    ngrams = delete(Ngrams({"test" => 1}), Ngrams({"test" => 2}))
    @fact ngrams => Ngrams()
  end
end
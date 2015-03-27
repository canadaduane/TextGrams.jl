facts("NgramsSets") do
  context("unionAdd same keys") do
    ngrams = unionAdd(Ngrams({"test" => 1}), Ngrams({"test" => 2}))
    @fact ngrams["test"] => 3
  end

  context("unionAdd new keys") do
    ngrams = unionAdd(Ngrams({"test" => 1}), Ngrams({"new" => 2}))
    @fact ngrams => {"test" => 1, "new" => 2}
  end

  context("leftJoinAdd same keys") do
    ngrams = leftJoinAdd(Ngrams({"test" => 1}), Ngrams({"test" => 2}))
    @fact ngrams => {"test" => 3}
  end

  context("leftJoinAdd new keys") do
    ngrams = leftJoinAdd(Ngrams({"test" => 1}), Ngrams({"new" => 2}))
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

  context("intersectAdd same keys") do
    ngrams = intersectAdd(Ngrams({"test" => 1}), Ngrams({"test" => 2, "other" => 1}))
    @fact ngrams => {"test" => 3}
  end

  context("intersectAdd disjunct keys") do
    ngrams = intersectAdd(Ngrams({"test" => 1}), Ngrams({"new" => 2}))
    @fact ngrams => Dict{ASCIIString,Integer}()
  end

  context("intersectAdd multiple Ngrams") do
    ngrams = intersectAdd(
      Ngrams({"a" => 1, "b" => 2, "c" => 3}),
      Ngrams({"a" => 2, "b" => 3, "z" => 10}),
      Ngrams({"a" => 3, "c" => 4, "y" => 12}))
    @fact ngrams => {"a" => 6}
  end
end
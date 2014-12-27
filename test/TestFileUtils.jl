facts("FileUtils") do
  context("splitFileList") do
    l1, l2 = splitFileList(["f1", "f2", "--", "f3"])
    @fact l1 => ["f1", "f2"]
    @fact l2 => ["f3"]

    l1, l2 = splitFileList(["f1", "..", "f3"], "..")
    @fact l1 => ["f1"]
    @fact l2 => ["f3"]
  end
end
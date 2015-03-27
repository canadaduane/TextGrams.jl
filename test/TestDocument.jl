facts("Document") do
  context("is cleaned") do
    doc = Document("1--This, Document!!")
    @fact doc.content => "this document"
    @fact doc.title => "this document"
  end

  context("sets title") do
    doc = Document("1--This, Document!!", "test-doc")
    @fact doc.title => "test-doc"
  end

  context("reads file") do
    doc = Document(open(fixture("samples/liahona.txt")), "liahona")
    @fact ismatch(r"^and it came to pass", doc.content) => true
  end
end


TextGrams is a Julia library that takes documents and slices them into ngrams and counts the occurrences. Given a baseline of ngram frequencies, it can then compare 2 or more documents for similarity using rare ngram matching.

## Example Usage

```julia
using TextGrams
using MutableStrings

# Normalize some text
text1 = MutableASCIIString("This real-\nly, sorta, works!")
clean!(text1)
println(text1) # => "this really sorta works"


# Create a document
doc1 = Document(text1, "A Real Document")
# Note: you can also open 
doc1.title # => "A Real Document"
doc1.content # => "this really sorta works"

# Slice the document into Ngrams of size 2 or fewer
ng1 = Ngrams(doc1, 2)

# => Dict{ASCIIString,Integer} with 7 entries:
#   "sorta works"  => 1
#   "this really"  => 1
#   "this"         => 1
#   "sorta"        => 1
#   "really"       => 1
#   "really sorta" => 1
#   "works"        => 1

# Create another document
doc2 = Document("I guess it sorta works.")
ng2 = Ngrams(doc2, 2)

# Find the intersection of ngrams
intersectAdd(ng1, ng2)

# => Dict{ASCIIString,Integer} with 3 entries:
#   "sorta works" => 2
#   "sorta"       => 2
#   "works"       => 2

```

## More Info

See our blog, on [Using TextGrams.jl](http://blog.wordtree.org/2015/03/29/using-textgrams-jl/).

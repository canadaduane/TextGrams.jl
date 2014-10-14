
```julia
using TextGrams

text1 = MutableASCIIString("This")
println(text1)
clean!(text1)
println(text1)

text2 = MutableASCIIString("And this text is also cool!")
println(text2)
clean!(text2)
println(text2)

d1 = ngramize(text1, 3)
println("d1 " ,d1)

d2 = ngramize(text2, 3)
println("d2 ", d2)

add!(d1, d2)

println("d1 + d2 ", d1)
```
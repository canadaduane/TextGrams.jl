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

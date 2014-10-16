@everywhere using TextGrams
@everywhere using MutableStrings
@everywhere import Base.copy

if length(ARGS) == 0
  println("USAGE: baseline [FILES_OR_DIRS]")
  exit()
end

@everywhere begin
  type NgramData
    content::MutableASCIIString
    title::String
    ngrams::Dict{String,Integer}
  end

  function ngram_data(path, n = 4)
    content = MutableASCIIString(ioread(path))
    short = length(content) > 35 ? content[1:35] : content
    clean!(content)
    ngrams = ngramize(content, n)
    NgramData(content, replace(short, r"\s+", " "), ngrams)
  end

  function copy(data::NgramData)
    NgramData(data.content, copy(data.title), copy(data.ngrams))
  end

  function ioread(file)
    content = ""
    open(file) do fh
      content = readall(fh)
    end
    return content
  end

end

function pconsume(fn::Function, producer::Task, args...)
  np = nprocs()
  @sync begin
    for p = 1:np
      if p != myid() || np == 1
        @async begin
          for x in producer
            remotecall_fetch(p, fn, x, args...)
          end
        end
      end
    end
  end
end

# tic()
# @printf("loading bom...\n")
# global ref_path = joinpath(dirname(@__FILE__), "test", "bom.txt")
# global sreference = ngram_data(ref_path)
# global greference = Dict{String,Integer}
# toc()

# producer = @task(file_producer(ARGS))
# np = nprocs()
# @sync begin
#   for p = 1:np
#     if p != myid() || np == 1
#       @async begin
#         reference = copy(sreference)
#         @printf("starting %d\n", p)
#         function fn(x)
#           @printf("%45s\n", basename(x))
#           intersect_add!(reference.ngrams, ngram_data(x).ngrams)
#         end
#         for x in producer
#           remotecall_fetch(p, fn, x)
#         end
#         @printf("done %d\n", myid())
#         union_add!(greference, reference.ngrams)
#       end
#     end
#   end
# end

# println("sreference: ", length(sreference))
# println("greference: ", length(greference))
tic()
baseline = Dict{String,Integer}()

pconsume(@task(file_producer(ARGS))) do file
  @printf("%45s\n", basename(file))
  data = ngram_data(file)
  # intersect_add!(reference.ngrams, data.ngrams)
  @printf("%45s (%s ngrams): %s\n", basename(file), length(data.ngrams), data.title)
end
toc()

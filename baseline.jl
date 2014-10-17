using ArgParse

global ref_list = Dict{Integer,RemoteRef}()
global settings

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--precedent", "-p"
            help = "set the 'precedent' file upon which all other ngrams will be based"
            nargs = 1
        "--verbose", "-v"
            help = "show progress updates"
            action = :store_true
        "--no-output"
            help = "don't show key/value result"
            action = :store_true
        "--ngrams", "-n"
            help = "the N in ngrams (e.g. '3' to create up to 3-grams)"
            nargs = 1
            arg_type = Integer
            default = Integer[3]
        "FILES"
            help = "files or directories to show"
            required = true
            nargs = '*'
    end

    return parse_args(s)
end

settings = parse_commandline()

function msg(m...)
  if settings["verbose"]
    println(m...)
  end
end

function maybe_timed(fn::Function, m...)
  msg(m...)
  if settings["verbose"]
    tic()
  end
  fn()
  if settings["verbose"]
    toc()
  end
end

# global precedent_path = joinpath(dirname(@__FILE__), "test", "bom.txt")
if length(settings["precedent"]) > 0
  global precedent_path = first(settings["precedent"])
else
  error("precedent document is required (use '-p')")
end

if nprocs() < 2
  addprocs(1)
end

@everywhere using TextGrams
@everywhere using MutableStrings
@everywhere import Base.copy

@everywhere begin
  type NgramData
    content::MutableASCIIString
    title::String
    ngrams::Dict{ASCIIString,Integer}
  end

  function ngram_data(path, n = 3)
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

function peach(fn::Function, producer::Task, args...)
  np = nprocs()
  @sync begin
    for p = 1:np
      if p != myid() || np == 1
        @async begin
          for x in producer
            wait(remotecall(p, fn, x, args...))
          end
        end
      end
    end
  end
end

msg("Loading precedent doc $(precedent_path)...")
# Load once
precedent_data, t, m = @timed remotecall_fetch(1, ngram_data, precedent_path, first(settings["ngrams"]))
m_mb = integer(m/1024/1024)
msg("time: $(t), memory: $(m_mb) MB, keys: $(length(precedent_data.ngrams))")

maybe_timed("Distribute precedent doc...") do
  # Distribute everywhere
  for p in 2:nprocs()
    msg("  Sending $(m_mb) MB to $(p-1)/$(nworkers()) workers")
    rr = RemoteRef(p)
    ref_list[p] = rr
    put!(rr, precedent_data)
  end
end

maybe_timed("Extracting $(first(settings["ngrams"]))-grams (map)...") do
  files = settings["FILES"]
  peach(@task(file_producer(files)), ref_list, settings) do file, ref_list, settings
    if settings["verbose"]
      @printf("%45s processing...\n", basename(file))
    end
    local precedent_data = fetch(ref_list[myid()])
    new_data = ngram_data(file, first(settings["ngrams"]))
    intersect_add!(precedent_data.ngrams, new_data.ngrams)
    if settings["verbose"]
      @printf("%45s Done: added %s ngrams\n", basename(file), length(new_data.ngrams))
    end
  end
end

final_ngrams = Dict{ASCIIString,Integer}()
maybe_timed("Combining ngrams (reduce)...") do
  for (k,v) in ref_list
    data = fetch(v)
    msg("$k -> $(length(data.ngrams))")
    union_add!(final_ngrams, data.ngrams)
  end
end

maybe_timed("Removing duplicate counts...") do
  nw = nworkers()-1 # minus one here because we want *one* copy of the counts to remain
  for (k,v) in precedent_data.ngrams
    fv = final_ngrams[k]
    if fv >= v*nw
      final_ngrams[k] = fv - v*nw
    else
      error("should be less")
    end
  end
end

if !settings["no-output"]
  for (k,v) in final_ngrams
    println(k, "\t", v)
  end
end
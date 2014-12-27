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
        "--ignore-results"
            help = "don't show key/value result"
            action = :store_true
        "--ngrams", "-n"
            help = "the N in ngrams (e.g. '3' to create up to 3-grams)"
            nargs = 1
            arg_type = Integer
            default = Integer[3]
        "FILES"
            help = "files or directories to include in baseline"
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
precedent_ngrams, t, m = @timed remotecall_fetch(1, ngramsOfTextFile, precedent_path, None, first(settings["ngrams"]))
m_mb = integer(m/1024/1024)
msg("time: $(t), memory: $(m_mb) MB, keys: $(length(precedent_ngrams))")

maybe_timed("Distribute precedent doc...") do
  # Distribute everywhere
  for p in 2:nprocs()
    msg("  Sending $(m_mb) MB to $(p-1)/$(nworkers()) workers")
    rr = RemoteRef(p)
    ref_list[p] = rr
    put!(rr, precedent_ngrams)
  end
end

maybe_timed("Extracting $(first(settings["ngrams"]))-grams (map)...") do
  files = settings["FILES"]
  peach(@task(fileProducer(files)), ref_list, settings) do file, ref_list, settings
    if settings["verbose"]
      @printf("%45s processing...\n", basename(file))
    end
    local precedent_ngrams = fetch(ref_list[myid()])
    ngrams = Ngrams(file, first(settings["ngrams"]))
    intersectAdd!(precedent_ngrams, ngrams)
    if settings["verbose"]
      @printf("%45s Done: added %s ngrams\n", basename(file), length(ngrams))
    end
  end
end

final_ngrams = Ngrams()
maybe_timed("Combining ngrams (reduce)...") do
  for (k,v) in ref_list
    ngrams = fetch(v)
    msg("$k -> $(length(ngrams))")
    unionAdd!(final_ngrams, ngrams)
  end
end

maybe_timed("Removing duplicate counts...") do
  nw = nworkers()-1 # minus one here because we want *one* copy of the counts to remain
  for (k,v) in precedent_ngrams
    fv = final_ngrams[k]
    if fv >= v*nw
      final_ngrams[k] = fv - v*nw
    else
      error("should be less")
    end
  end
end

if !settings["ignore-results"]
  for (k,v) in final_ngrams
    println(k, "\t", v)
  end
end
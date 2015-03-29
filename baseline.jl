using ArgParse
using TextGrams

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
            arg_type = Integer
            default = 3
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
    println(STDERR, m...)
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

baseline =
  if length(settings["precedent"]) == 1
    msg("Using precedent ", settings["precedent"][1])
    Ngrams(Document(open(settings["precedent"][1])), settings["ngrams"])
  else
    msg("No precedent")
    Ngrams()
  end

for file in @task(fileProducer(settings["FILES"]))
  baselineSizeBefore = length(baseline)
  msg("Loading ", file)
  ngrams = Ngrams(Document(open(file)), settings["ngrams"])
  if length(settings["precedent"]) == 1
    msg("Intersecting")
    leftJoinAdd!(baseline, ngrams)
  else
    msg("Unioning")
    unionAdd!(baseline, ngrams)
  end

  baselineSize = length(baseline)
  msg(baselineSizeBefore, " (+ ", (baselineSize - baselineSizeBefore), " of ", length(ngrams), ")")
end

msg("----- RESULTS -----")
if !settings["ignore-results"]
  for (k,v) in baseline
    println(k, "\t", v)
  end
end

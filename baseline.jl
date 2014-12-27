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

baseline = Ngrams()

for file in @task(fileProducer(settings["FILES"]))
  baselineSizeBefore = length(baseline)
  msg(file)
  ngrams = Ngrams(Document(open(file)), settings["ngrams"][1])
  unionAdd!(baseline, ngrams)

  baselineSize = length(baseline)
  msg(baselineSizeBefore, " (+ ", (baselineSize - baselineSizeBefore), " of ", length(ngrams), ")")
end

if !settings["ignore-results"]
  for (k,v) in baseline
    println(k, "\t", v)
  end
end
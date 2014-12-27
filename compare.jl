using ArgParse
using TextGrams

global settings

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--verbose", "-v"
            help = "show progress updates"
            action = :store_true
        "--no-output"
            help = "don't show key/value result"
            action = :store_true
        "--baseline", "-b"
            help = "the baseline ngrams to use (a text file)"
            nargs = 1
        "--ngrams", "-n"
            help = "the N in ngrams (e.g. '3' to create up to 3-grams)"
            nargs = 1
            arg_type = Integer
            default = Integer[2]
        "FILES"
            help = "files or directories to cross compare, use 'X' to separate list A from list B"
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

baselinePath = settings["baseline"][1]

fileX, fileY = splitFileList(settings["FILES"], "X")
emptyLists = map(((f) -> length(f) == 0), {fileX, fileY})
if any(emptyLists)
  println("Two file lists are required. Separate the first list\n",
          "from the second with 'X', e.g.:\n\n",
          "file1.txt file2.txt X file3.txt file4.txt")
  exit(-1)
end

msg("baseline: ", baselinePath)
msg("files X: ", fileX)
msg("files Y: ", fileY)

function cross(fn, fileX, fileY)
  for fx in @task(fileProducer(fileX))
    for fy in @task(fileProducer(fileY))
      fn(fx, fy)
    end
  end
end

function loadAndCompare(baseline, fx, fy)
  xhandle = open(fx)
  yhandle = open(fy)
  # try
    nx = Ngrams(Document(xhandle),2)
    ny = Ngrams(Document(yhandle), 2)
    compare(baseline, nx, ny)
  # catch e
    # println("Skipping ", fx, " X ", fy, " (Not an ASCII file?)")
    # 0.0
  # end
end

function compare(baseline, nx, ny)
  total = 0
  for (ngram, freqbase) in baseline
    freqx = get(nx, ngram, 0)
    freqy = get(ny, ngram, 0)
    interscore = sqrt(freqx * freqy) / freqbase
    total += interscore
    # if interscore >= 1
      # println(ngram, " ", freqbase, ":", freqx, ",", freqy, " : ", interscore)
    # end
  end
  # println("total ", total)

  sx = int(sum(values(nx))/2)
  sy = int(sum(values(ny))/2)
  (total / sqrt(sx^2 + sy^2), sx, sy)
end

baseline = Ngrams(open(baselinePath))
cross(fileX, fileY) do fx, fy
  score, sizex, sizey = loadAndCompare(baseline, fx, fy)
  if length(fileX) == 1
    println(score, "\t", sizey, "\t", score/(sizey), "\t", fy)
  else
    println(score, "\t", sizex, "\t", sizey, "\t", fy, "\t", fx)
  end
end

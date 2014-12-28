using ArgParse
using TextGrams
using ProgressMeter
using AnsiColor

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

msg("Using baseline: ", baselinePath)
msg("Using files X: ", fileX)
msg("Using files Y: ", fileY)

function cross(fn, fileX, fileY)
  for fx in @task(fileProducer(fileX))
    for fy in @task(fileProducer(fileY))
      fn(fx, fy)
    end
  end
end

function loadAndCompare(baseline, fx, fy)
  # try
  # msg("Loading $(fx)...")
  nx = Ngrams(Document(open(fx)),2)
  # msg("Loading $(fy)...")
  ny = Ngrams(Document(open(fy)), 2)
  # msg("Comparing...")
  compare(baseline, nx, ny)
  # catch e
    # println("Skipping ", fx, " X ", fy, " (Not an ASCII file?)")
    # 0.0
  # end
end

function compare(baseline, nx, ny)
  total = 0
  sx = int(sum(values(nx))/2)
  sy = int(sum(values(ny))/2)

  if sx < sy
    for (ngram, freqx) in nx
      freqy = get(ny, ngram, 0)
      freqbase = get(baseline, ngram, 10000000)
      interscore = sqrt(freqx * freqy) / freqbase
      total += interscore
    # if interscore >= 1
      # println(ngram, " ", freqbase, ":", freqx, ",", freqy, " : ", interscore)
    # end
    end
  else
    for (ngram, freqy) in ny
      freqx = get(nx, ngram, 0)
      freqbase = get(baseline, ngram, 10000000)
      interscore = sqrt(freqx * freqy) / freqbase
      total += interscore
    end
  end

  (total / sqrt(sx^2 + sy^2), sx, sy)
end

function linesInFile(filename)
  wc = readall(`wc -l $(baselinePath)`)
  linecount, _ = split(strip(wc), " ")
  return int(linecount)
end

msg("Measuring baseline size...")
linecount = linesInFile(baselinePath)
p = Progress(linecount, 1, yellow("Loading baseline... "), 50)
baseline = @time Ngrams(open(baselinePath), (n) -> next!(p))

msg("\nCross comparing...")
cross(fileX, fileY) do fx, fy
  score, sizex, sizey = loadAndCompare(baseline, fx, fy)
  if length(fileX) == 1
    println(score, "\t", sizey, "\t", score/(sizey), "\t", fy)
  else
    println(score, "\t", sizey, "\t", sizex, "\t", fy, "\t", fx)
  end
end

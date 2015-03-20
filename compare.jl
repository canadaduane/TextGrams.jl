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
            arg_type = Integer
            default = 2
        "--show-matches", "-s"
            help = "show matching words with score above the threshold"
            action = :store_true
        "--threshold", "-t"
            help = "set the 'show-matches' threshold. Defaults to 0.25."
            arg_type = Float64
            default = 0.25
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
  x = 1
  for fx in @task(fileProducer(fileX))
    y = 1
    for fy in @task(fileProducer(fileY))
      if x <= y && fx != fy
        fn(fx, fy)
      end
      y += 1
    end
    x += 1
  end
end

function loadAndCompare(baseline, fx, fy, show_matches_threshold=0.25)
  try
    msg("Loading $(fx)...")
    nx = Ngrams(Document(open(fx)),2)
    msg("Loading $(fy)...")
    ny = Ngrams(Document(open(fy)), 2)
    msg("Comparing... $(fx) x $(fy)")
    compare(baseline, nx, ny, 4, fx, fy, show_matches_threshold)
  catch e
    println("Skipping ", fx, " X ", fy, " (Not an ASCII file?)")
    0.0
  end
end

function compare(baseline, nx, ny, unknownfreq=4, fx=None, fy=None, show_matches_threshold=0.25)
  total_inv = 0
  total_mul = 0
  total_sqr = 0
  sx = int(sum(values(nx))/2)
  sy = int(sum(values(ny))/2)

  if sy < sx
    sx, sy = sy, sx
    nx, ny = ny, nx
    fx, fy = fy, fx
  end

  saved_scores = Array(Any, 0)
  for (ngram, freqx) in nx
    freqy = get(ny, ngram, 0)
    if freqx > 0 && freqy > 0
      freqbase = get(baseline, ngram, unknownfreq)
      interscore_inv = 1.0 / freqbase
      interscore_mul = (freqx * freqy) / freqbase
      interscore_sqr = sqrt(freqx * freqy) / freqbase
      total_inv += interscore_inv
      total_mul += interscore_mul
      total_sqr += interscore_sqr
      if interscore_inv >= show_matches_threshold
        push!(saved_scores, (ngram, interscore_inv, interscore_mul, interscore_sqr))
      end
    end
  end

  nfx, _ = splitext(basename(fx))
  nfy, _ = splitext(basename(fy))

  if length(saved_scores) > 0
    for parts = sort(saved_scores, by = (t) -> t[2], rev=true)
      ngram, i_inv, i_mul, i_sqr = parts
      @printf("\t%s\t%0.3f\t%0.3f\t%0.3f\t%s\t%s\n", ngram, i_inv, i_mul, i_sqr, nfx, nfy)
    end
  end

  (total_inv, total_mul, total_sqr, sx, sy, nfx, nfy)
end

function linesInFile(filename)
  wc = readall(`wc -l $(baselinePath)`)
  linecount, _ = split(strip(wc), " ")
  return int(linecount)
end

msg("Measuring baseline size...")
linecount = linesInFile(baselinePath)
msg("  $(linecount) ngrams")
if settings["verbose"]
  p = Progress(linecount, 1, yellow("Loading baseline... "), 50)
  baseline = @time Ngrams(open(baselinePath), (n) -> next!(p))
else
  baseline = Ngrams(open(baselinePath))
end

msg("\nCross comparing...")
if !settings["show-matches"]
  @printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "total_inv", "total_mul", "total_sqrt", "sizex", "sizey", "namex", "namey")
end
cross(fileX, fileY) do fx, fy
  threshold = settings["show-matches"] ? settings["threshold"] : 1000000
  total_inv, total_mul, total_sqr, sizex, sizey, nfx, nfy = loadAndCompare(baseline, fx, fy, threshold)
  if settings["show-matches"]
    @printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", "total_inv", "total_mul", "total_sqrt", "sizex", "sizey", "namex", "namey")
  end
  @printf("%0.5f\t%0.5f\t%0.5f\t%d\t%d\t%s\t%s\n", total_inv, total_mul, total_sqr, sizex, sizey, nfx, nfy)
  if settings["show-matches"]
    println()
    println()
  end
end
